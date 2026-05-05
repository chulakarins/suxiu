import SwiftUI
import Foundation
import Combine

// MARK: - ViewModel

/// 内容视图模型 - 管理内容视图的状态和逻辑
///
/// 负责：
/// - 管理用户输入的提示词
/// - 管理图片生成状态 (加载中/成功/失败)
/// - 调用后端 API 进行图片生成
/// - 管理错误信息
class ContentViewModel: ObservableObject {
    /// 用户输入的提示词文本
    @Published var promptText: String = ""

    /// 生成的图片 URL
    @Published var generatedImageURL: String? = nil

    /// 加载状态 - true 表示正在生成图片
    @Published var isLoading: Bool = false

    /// 错误信息
    @Published var errorMessage: String? = nil

    /// 加载进度文字
    @Published var loadingText: String? = nil

    /// 生成图片
    @MainActor
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
        loadingText = "正在提交任务..."

        let prompt = promptText.trimmingCharacters(in: .whitespaces)

        Task {
            do {
                let url = try await APIClient.shared.generateAndPoll(
                    prompt: prompt,
                    progressUpdate: { status, progress in
                        self.loadingText = self.statusText(status: status, progress: progress)
                    }
                )
                generatedImageURL = url
                loadingText = "生成完成！"
            } catch APIClientError.unauthenticated {
                errorMessage = "登录已过期，请重新登录"
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func statusText(status: String, progress: Int) -> String {
        switch status {
        case "pending": return "正在排队，请稍候... \(progress)%"
        case "running": return "正在生成苏绣设计... \(progress)%"
        case "succeeded": return "生成完成！"
        default: return "正在生成... \(progress)%"
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

                // 左上角装饰
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 0.2, green: 0.48, blue: 0.95).opacity(0.15))
                    .offset(x: -50, y: -30)

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
