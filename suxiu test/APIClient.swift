import Foundation

// MARK: - APIClientError

enum APIClientError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(Int, String)
    case decodingError
    case unauthenticated

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL 无效"
        case .networkError(let e): return "网络错误：\(e.localizedDescription)"
        case .serverError(let code, let msg): return "服务器错误 (\(code))：\(msg)"
        case .decodingError: return "数据解析失败"
        case .unauthenticated: return "登录已过期，请重新登录"
        }
    }
}

// MARK: - APIClient

/// 统一网络客户端 - 管理后端 API 调用和 Token 生命周期
class APIClient {

    // MARK: Configuration

    /// 后端 Base URL - 开发环境用 Mac 局域网 IP
    static let shared = APIClient()

    #if targetEnvironment(simulator)
    private let baseURL: String = "http://localhost:8000"
    #else
    private let baseURL: String = "http://172.16.7.184:8000"
    #endif

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 300.0
        return URLSession(configuration: config)
    }()

    // MARK: Token Storage

    private let tokenKey = "suxiu_access_token"
    private let refreshTokenKey = "suxiu_refresh_token"
    private let userIDKey = "suxiu_user_id"
    private let usernameKey = "suxiu_username"

    var accessToken: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    var refreshToken: String? {
        UserDefaults.standard.string(forKey: refreshTokenKey)
    }

    var isLoggedIn: Bool {
        accessToken != nil
    }

    private func storeTokens(accessToken: String, refreshToken: String, userId: String, username: String) {
        UserDefaults.standard.set(accessToken, forKey: tokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        UserDefaults.standard.set(userId, forKey: userIDKey)
        UserDefaults.standard.set(username, forKey: usernameKey)
    }

    func clearTokens() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: usernameKey)
    }

    // MARK: Request Builder

    private func request(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIClientError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return urlRequest
    }

    private func execute<T: Decodable>(_ urlRequest: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await urlSession.data(for: urlRequest)

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 401 {
                throw APIClientError.unauthenticated
            }
            if http.statusCode != 200 {
                let raw = String(data: data, encoding: .utf8) ?? ""
                throw APIClientError.serverError(http.statusCode, raw)
            }
        }

        // 后端统一响应格式: { code, message, data }
        let envelope = try JSONDecoder().decode(APIEnvelope<T>.self, from: data)
        if envelope.code != 0 {
            throw APIClientError.serverError(envelope.code, envelope.message ?? "未知错误")
        }

        guard let data = envelope.data else {
            throw APIClientError.decodingError
        }
        return data
    }

    private func executeRaw(_ urlRequest: URLRequest) async throws -> (Int, [String: Any]) {
        let (data, response) = try await urlSession.data(for: urlRequest)

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 401 {
                throw APIClientError.unauthenticated
            }
            if http.statusCode != 200 {
                let raw = String(data: data, encoding: .utf8) ?? ""
                throw APIClientError.serverError(http.statusCode, raw)
            }
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIClientError.decodingError
        }

        let code = json["code"] as? Int ?? -1
        return (code, json)
    }

    // MARK: - Auth APIs

    /// 注册
    func register(username: String, password: String) async throws -> AuthResult {
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        let urlRequest = try await request(path: "/api/v1/auth/register", method: "POST", body: body, requiresAuth: false)
        let result: AuthResult = try await execute(urlRequest, as: AuthResult.self)
        storeTokens(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
            userId: result.userId,
            username: result.username
        )
        return result
    }

    /// 登录
    func login(username: String, password: String) async throws -> AuthResult {
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        let urlRequest = try await request(path: "/api/v1/auth/login", method: "POST", body: body, requiresAuth: false)
        let result: AuthResult = try await execute(urlRequest, as: AuthResult.self)
        storeTokens(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
            userId: result.userId,
            username: result.username
        )
        return result
    }

    /// 自动认证：先尝试登录，用户不存在时自动注册，密码错误时直接报错
    func autoAuth(username: String, password: String) async throws -> AuthResult {
        do {
            return try await login(username: username, password: password)
        } catch APIClientError.serverError(1002, _) {
            // 密码错误 → 不尝试注册，直接抛出认证失败
            throw APIClientError.serverError(1002, "用户名或密码错误")
        } catch {
            // 用户不存在或其他错误 → 尝试注册
            do {
                return try await register(username: username, password: password)
            } catch APIClientError.serverError(1001, _) {
                // 注册失败（用户名已存在），说明之前是密码错误，抛出原始错误
                throw APIClientError.serverError(1002, "用户名或密码错误")
            }
        }
    }

    // MARK: - Design APIs

    /// 提交 AI 生成任务
    func generateDesign(prompt: String, style: String = "traditional", size: String = "1280*1280") async throws -> DesignGenerateResult {
        let body: [String: Any] = [
            "prompt": prompt,
            "style": style,
            "size": size
        ]
        let urlRequest = try await request(path: "/api/v1/design/generate", method: "POST", body: body)
        let result: DesignGenerateResult = try await execute(urlRequest, as: DesignGenerateResult.self)
        return result
    }

    /// 查询任务状态
    func queryTaskStatus(taskId: String) async throws -> TaskStatusResult {
        let urlRequest = try await request(path: "/api/v1/design/task/\(taskId)")
        let result: TaskStatusResult = try await execute(urlRequest, as: TaskStatusResult.self)
        return result
    }

    /// 轮询任务直到完成（封装 generate + 轮询）
    func generateAndPoll(prompt: String, progressUpdate: (@Sendable (String, Int) -> Void)? = nil) async throws -> String {
        // 提交任务
        let genResult = try await generateDesign(prompt: prompt)
        let taskId = genResult.taskId ?? genResult.designId
        progressUpdate?("pending", 0)

        // 轮询
        let maxAttempts = 120
        let interval: UInt64 = 2_000_000_000  // 2 秒

        for attempt in 1...maxAttempts {
            try await Task.sleep(nanoseconds: interval)

            let status = try await queryTaskStatus(taskId: taskId)
            let progress = status.progress ?? (attempt * 80 / maxAttempts)

            progressUpdate?(status.status, progress)

            switch status.status {
            case "succeeded":
                if let imageUrl = status.result?.imageUrl {
                    progressUpdate?("succeeded", 100)
                    return imageUrl
                }
                throw APIClientError.decodingError
            case "failed":
                throw APIClientError.serverError(-1, status.message ?? "生成失败")
            default:
                break  // pending / running -> continue polling
            }
        }

        throw APIClientError.serverError(-1, "任务超时，请稍后重试")
    }
}

// MARK: - Data Models

struct APIEnvelope<T: Decodable>: Decodable {
    let code: Int
    let message: String?
    let data: T?
}

struct AuthResult: Decodable {
    let userId: String
    let username: String
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

struct DesignGenerateResult: Decodable {
    let taskId: String?
    let designId: String

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case designId = "design_id"
    }
}

struct TaskStatusResult: Decodable {
    let taskId: String
    let status: String
    let progress: Int?
    let result: TaskResult?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case status
        case progress
        case result
        case message
    }
}

struct TaskResult: Decodable {
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
    }
}
