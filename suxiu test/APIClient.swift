import Foundation

// MARK: - APIClientError

enum APIClientError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(Int, String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL 无效"
        case .networkError(let e): return "网络错误：\(e.localizedDescription)"
        case .serverError(let code, let msg): return "服务器错误 (\(code))：\(msg)"
        case .decodingError: return "数据解析失败"
        }
    }
}

// MARK: - APIClient

/// 统一网络客户端 - 管理后端 API 调用
final class APIClient {

    static let shared = APIClient()

    #if targetEnvironment(simulator)
    private let baseURL: String = "http://127.0.0.1:8000"
    #else
    private let baseURL: String = "http://192.168.31.17:8000"
    #endif

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 300.0
        return URLSession(configuration: config)
    }()

    // MARK: Request Builder

    private func request(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIClientError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return urlRequest
    }

    // MARK: Network Executor

    private func execute<T: Decodable>(_ urlRequest: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await urlSession.data(for: urlRequest)

        if let http = response as? HTTPURLResponse {
            if http.statusCode != 200 {
                let raw = String(data: data, encoding: .utf8) ?? ""
                throw APIClientError.serverError(http.statusCode, raw)
            }
        }

        let envelope = try JSONDecoder().decode(APIEnvelope<T>.self, from: data)
        if envelope.code != 0 {
            throw APIClientError.serverError(envelope.code, envelope.message ?? "未知错误")
        }

        guard let payload = envelope.data else {
            throw APIClientError.decodingError
        }
        return payload
    }

    // MARK: - Design APIs

    /// 提交 AI 生成任务
    func generateDesign(prompt: String, style: String = "traditional", size: String = "1280*1280") async throws -> DesignGenerateResult {
        let body: [String: Any] = [
            "prompt": prompt,
            "style": style,
            "size": size
        ]
        let urlRequest = try request(path: "/api/v1/design/generate", method: "POST", body: body)
        return try await execute(urlRequest, as: DesignGenerateResult.self)
    }

    /// 查询任务状态
    func queryTaskStatus(taskId: String) async throws -> TaskStatusResult {
        let urlRequest = try request(path: "/api/v1/design/task/\(taskId)")
        return try await execute(urlRequest, as: TaskStatusResult.self)
    }

    /// 提交生成任务并轮询直到完成
    func generateAndPoll(prompt: String, progressUpdate: (@Sendable (String, Int) -> Void)? = nil) async throws -> String {
        let genResult = try await generateDesign(prompt: prompt)
        let taskId = genResult.taskId ?? genResult.designId
        progressUpdate?("pending", 0)

        let maxAttempts = 60
        let interval: UInt64 = 5_000_000_000  // 5 秒

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
                break
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
        case status, progress, result, message
    }
}

struct TaskResult: Decodable {
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
    }
}
