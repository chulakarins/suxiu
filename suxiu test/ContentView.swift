import SwiftUI
import Foundation
import Combine

// MARK: - AIImageService

/// AI 图像服务 - 负责调用通义万相 API 生成苏绣风格图片
///
/// 使用 Alibaba DashScope API (通义万相) 进行文生图操作
/// 支持异步任务提交和轮询查询结果
class AIImageService {
    /// API Key - 用于身份验证
    /// - Note: 生产环境建议使用 Keychain 或环境变量存储，避免硬编码
    private let apiKey = "sk-d5f6f3edc558444baff5b26af58536f8"

    /// 懒加载 URLSession 配置
    /// - 请求超时：60 秒
    /// - 资源超时：300 秒 (5 分钟)
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 300.0
        return URLSession(configuration: config)
    }()

    /// 生成苏绣风格图片 URL
    /// - Parameter prompt: 用户输入的提示词
    /// - Returns: 生成的图片 URL
    /// - Throws: 网络错误、API 错误、解析错误等
    func generateSuxiuImageURL(prompt: String) async throws -> String {
        print("[API] 开始生成，提示词：\(prompt)")
        let imageURL = try await submitTask(prompt: prompt)
        print("[API] 获得图片 URL：\(imageURL)")
        return imageURL
    }

    /// 提交图像生成任务到通义万相 API
    /// - Parameter prompt: 原始提示词
    /// - Returns: 任务 ID
    /// - Throws: URL 错误、API 错误、JSON 解析错误
    private func submitTask(prompt: String) async throws -> String {
        /// API 端点 - 通义万相文生图服务
        let endpoint = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis"

        /// 苏绣风格提示词后缀 - 用于生成专业苏绣效果
        /// 包含：微距摄影、手工丝线、可见纤维、精致针法等关键词
        let suxiuSuffix = ", ultra realistic macro photography of traditional suzhou embroidery (苏绣), hand stitched silk threads, visible thread fibers, delicate needlework details, natural fabric folds, subtle thread tension variations, silk texture with soft light scattering, micro reflections on threads, 100mm macro lens, shallow depth of field, realistic bokeh, soft studio lighting, gentle shadows, slight natural imperfections, documentary style textile photography, extremely detailed craftsmanship"

        /// 完整提示词 = 用户输入 + 苏绣风格后缀
        let fullPrompt = prompt + suxiuSuffix

        /// 负向提示词 - 排除不想要的效果
        /// 排除：CGI、3D 渲染、塑料质感、卡通、动漫、油画、水彩等
        let negativePrompt = "CGI, 3D render, plastic texture, artificial smooth surfaces, over-sharpening, glossy AI effect, cartoon, anime, digital illustration, oil painting, watercolor, brush strokes, low quality"

        /// API 请求体
        let body: [String: Any] = [
            "model": "wan2.5-t2i-preview",  // 通义万相预览模型
            "input": [
                "prompt": fullPrompt,
                "negative_prompt": negativePrompt
            ],
            "parameters": [
                "size": "1280*1280",        // 正方形图片
                "n": 1,                      // 生成 1 张
                "prompt_extend": true,       // 启用提示词扩展
                "watermark": false           // 不添加水印
            ]
        ]

        // 构建请求 URL
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "URLError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "API 地址无效"])
        }

        // 配置 HTTP 请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("enable", forHTTPHeaderField: "X-DashScope-Async")  // 启用异步处理
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // 发送请求并等待响应
        let (data, response) = try await urlSession.data(for: request)

        // 检查 HTTP 状态码
        if let http = response as? HTTPURLResponse {
            print("[API] HTTP 状态码：\(http.statusCode)")
            if http.statusCode != 200 {
                let raw = String(data: data, encoding: .utf8) ?? ""
                print("[API] 请求失败：\(raw)")
                throw NSError(domain: "APIError", code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "请求失败 (\(http.statusCode))\n\(raw)"])
            }
        }

        // 记录原始响应
        let raw = String(data: data, encoding: .utf8) ?? ""
        print("[API] 响应：\(raw)")

        // 解析 JSON 响应
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "ParseError", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "响应不是有效 JSON"])
        }

        // 检查 API 错误码和错误信息
        if let code = dict["code"] as? String, let msg = dict["message"] as? String {
            throw NSError(domain: "APIError", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "API 错误：\(msg) (code: \(code))"])
        }

        // 提取任务 ID
        guard let output = dict["output"] as? [String: Any],
              let taskId = output["task_id"] as? String else {
            throw NSError(domain: "ParseError", code: -5,
                          userInfo: [NSLocalizedDescriptionKey: "无法提取 task_id\n\(raw)"])
        }

        print("[API] 任务已提交，task_id: \(taskId)")
        // 轮询查询任务结果
        return try await pollTaskResult(taskId: taskId)
    }

    /// 轮询查询任务结果
    /// - Parameter taskId: 任务 ID
    /// - Returns: 成功时返回图片 URL
    /// - Throws: URL 错误、查询错误、解析错误、超时错误
    private func pollTaskResult(taskId: String) async throws -> String {
        /// 最大轮询次数 (30 次)
        let maxAttempts = 30
        /// 轮询间隔 (5 秒)
        let pollInterval: UInt64 = 5_000_000_000

        // 开始轮询
        for attempt in 1...maxAttempts {
            print("[Poll] 第\(attempt)次查询...")

            // 构建查询 URL
            guard let url = URL(string: "https://dashscope.aliyuncs.com/api/v1/tasks/\(taskId)") else {
                throw NSError(domain: "URLError", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "查询 URL 无效"])
            }

            // 配置查询请求
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

            // 发送查询请求
            let (pollData, pollResponse) = try await urlSession.data(for: request)

            // 检查 HTTP 状态码
            if let http = pollResponse as? HTTPURLResponse, http.statusCode != 200 {
                let errRaw = String(data: pollData, encoding: .utf8) ?? ""
                throw NSError(domain: "QueryError", code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "查询失败：\(errRaw)"])
            }

            // 记录原始响应
            let raw = String(data: pollData, encoding: .utf8) ?? ""
            print("[Poll] 响应：\(raw)")

            // 解析 JSON 响应
            guard let dict = try JSONSerialization.jsonObject(with: pollData) as? [String: Any] else {
                throw NSError(domain: "ParseError", code: -5,
                              userInfo: [NSLocalizedDescriptionKey: "无法解析任务状态"])
            }

            // 提取任务状态
            let output = dict["output"] as? [String: Any] ?? [:]
            let taskStatus = output["task_status"] as? String ?? "UNKNOWN"

            print("[Poll] 任务状态：\(taskStatus)")

            // 根据任务状态处理
            switch taskStatus {
            case "SUCCEEDED":
                // 任务成功，提取图片 URL
                if let results = output["results"] as? [[String: Any]],
                   let first = results.first,
                   let imageURL = first["url"] as? String {
                    print("[Poll] 成功，图片 URL：\(imageURL)")
                    return imageURL
                }
                throw NSError(domain: "ParseError", code: -6,
                              userInfo: [NSLocalizedDescriptionKey: "无法提取图片 URL"])
            case "FAILED":
                // 任务失败，抛出错误
                let msg = output["message"] as? String ?? "任务失败"
                let errCode = output["code"] as? String ?? "未知"
                throw NSError(domain: "TaskError", code: -7,
                              userInfo: [NSLocalizedDescriptionKey: "生成失败：\(msg) (code: \(errCode))"])
            default:
                // 其他状态 (PENDING/RUNNING)，继续轮询
                print("[Poll] 状态：\(taskStatus)，5 秒后重试...")
                try await Task.sleep(nanoseconds: pollInterval)
            }
        }

        // 超过最大轮询次数，抛出超时错误
        throw NSError(domain: "TimeoutError", code: -8,
                      userInfo: [NSLocalizedDescriptionKey: "任务超时，请稍后重试"])
    }
}

// MARK: - ViewModel

/// 内容视图模型 - 管理内容视图的状态和逻辑
///
/// 负责：
/// - 管理用户输入的提示词
/// - 管理图片生成状态 (加载中/成功/失败)
/// - 调用 AIImageService 进行图片生成
/// - 管理错误信息
@MainActor
class ContentViewModel: ObservableObject {
    /// 用户输入的提示词文本
    @Published var promptText: String = ""

    /// 生成的图片 URL
    @Published var generatedImageURL: String? = nil

    /// 加载状态 - true 表示正在生成图片
    @Published var isLoading: Bool = false

    /// 错误信息
    @Published var errorMessage: String? = nil

    /// AI 图像服务实例
    private let service = AIImageService()

    /// 生成图片
    ///
    /// 验证输入后调用 API 生成苏绣风格图片
    /// - 输入为空时设置错误信息
    /// - 成功时更新 generatedImageURL
    /// - 失败时更新 errorMessage
    func generateImage() {
        // 验证输入 - 去除空格后不能为空
        guard !promptText.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "请输入描述内容"
            return
        }

        // 重置状态
        isLoading = true
        errorMessage = nil
        generatedImageURL = nil

        // 异步执行图片生成
        Task {
            do {
                let url = try await service.generateSuxiuImageURL(prompt: promptText)
                generatedImageURL = url
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - ContentView

/// 内容视图 - AI 图片生成主界面
///
/// 提供：
/// - 用户输入提示词的输入框
/// - 显示生成的苏绣风格图片
/// - 加载状态和错误提示
/// - 底部输入栏 (包含图片、麦克风、发送、添加按钮)
struct ContentView: View {
    /// 视图模型
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationView {
            ZStack(alignment: .topLeading) {
                // 背景色 - 浅蓝灰 - 延伸到导航栏下面
                Color(red: 0.91, green: 0.94, blue: 0.96)
                    .ignoresSafeArea(edges: .top)

                // 左上角固定装饰图 - 超出屏幕边界
                Image("SuxiuPattern")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
                    .offset(x: -50, y: -50)
                    .opacity(0.85)

                // 主内容区域 - 可滚动
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // 顶部留白，避开装饰图
                        Spacer().frame(height: 140)

                        Text("输入您的创意想法")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)

                        Text("AI 将为您生成设计图案")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)

                        Spacer().frame(height: 20)

                        // 生成结果区域
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("生成中，请稍候...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .frame(height: 300)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                        }

                        if let urlString = viewModel.generatedImageURL,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 300)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                        .padding(.horizontal, 24)
                                case .failure:
                                    Text("图片加载失败")
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }

                        Spacer(minLength: 120)
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("锦绣 AI")
                        .font(.system(size: 17, weight: .semibold))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.secondary)
                        .font(.system(size: 22))
                }
            }
            #endif
            .safeAreaInset(edge: .bottom) {
                BottomInputBar(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Bottom Input Bar

/// 底部输入栏组件
///
/// 提供类似聊天界面的输入体验：
/// - 图片按钮：用于上传图片
/// - 文本输入框：输入提示词
/// - 发送/麦克风按钮：有文字时显示发送按钮，否则显示麦克风
/// - 加号按钮：更多功能入口
struct BottomInputBar: View {
    /// 关联的视图模型
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 图片按钮 - 用于上传图片参考
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
                    .font(.system(size: 20))

                // 文本输入框 - 输入提示词
                TextField("发消息或按住说话...", text: $viewModel.promptText)
                    .font(.system(size: 15))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .cornerRadius(20)

                // 发送/麦克风按钮 - 根据输入状态切换
                if viewModel.promptText.isEmpty {
                    // 空输入时显示麦克风按钮
                    Image(systemName: "mic")
                        .foregroundColor(.secondary)
                        .font(.system(size: 20))
                } else {
                    // 有输入时显示发送按钮
                    Button(action: { viewModel.generateImage() }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isLoading)  // 加载中时禁用
                }

                // 加号按钮 - 更多功能
                Image(systemName: "plus")
                    .foregroundColor(.secondary)
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.91, green: 0.94, blue: 0.96))
        }
    }
}

#Preview {
    ContentView()
}
