#if os(iOS)
import SwiftUI
import PhotosUI
import UIKit
import Combine

// MARK: - iOS Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - AIGenerateView

struct AIGenerateView: View {
    @StateObject private var viewModel = AIGenerateViewModel()
    @StateObject private var voiceRecorder = VoiceRecorder()

    @State private var showingImagePicker = false
    @State private var showingPHPicker = false
    @State private var imageSourceType: ImagePicker.SourceType = .photoLibrary
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // 背景色
                Color(red: 0.94, green: 0.96, blue: 0.97)
                    .ignoresSafeArea(edges: .top)

                // 左上角装饰
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 0.2, green: 0.48, blue: 0.95).opacity(0.15))
                    .offset(x: -50, y: -30)

                // 主内容区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Spacer().frame(height: 140)

                        Text("输入您的创意想法")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)

                        Text("AI 将为您生成专业苏绣设计图")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)

                        Spacer().frame(height: 20)

                        // 已选图片预览
                        if !viewModel.selectedImages.isEmpty {
                            imagePreviewSection
                                .padding(.horizontal, 24)
                        }

                        // 生成结果区域
                        if viewModel.isLoading {
                            loadingView
                                .frame(height: 300)
                        }

                        if let error = viewModel.errorMessage {
                            ErrorView(message: error)
                                .padding(.horizontal, 24)
                        }

                        if let imageURL = viewModel.generatedImageURL {
                            ResultView(imageURL: imageURL)
                                .padding(.horizontal, 24)
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
                    Text("AI 生成")
                        .font(.system(size: 17, weight: .semibold))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.secondary)
                            .font(.system(size: 22))
                    }
                }
            }
            #endif
            .safeAreaInset(edge: .bottom) {
                InputBar(
                    viewModel: viewModel,
                    voiceRecorder: voiceRecorder,
                    onImagePickerRequest: { sourceType in
                        imageSourceType = sourceType
                        showingImagePicker = true
                    }
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(
                    onImageSelected: { image in
                        viewModel.addImage(image)
                    },
                    sourceType: imageSourceType
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = viewModel.generatedImage {
                    ShareSheet(activityItems: [image])
                }
            }
        }
    }

    // MARK: - 子视图

    private var imagePreviewSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.selectedImages, id: \.id) { image in
                    ImagePreview(
                        image: image.image,
                        onRemove: {
                            viewModel.removeImage(image.id)
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("正在生成苏绣设计，请稍候...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let progressText = viewModel.loadingText {
                    Text(progressText)
                        .font(.caption2)
                        .foregroundColor(Color(.systemGray3))
                }
            }
            Spacer()
        }
    }

    private func ResultView(imageURL: String) -> some View {
        VStack(spacing: 0) {
            Group {
                if let url = URL(string: imageURL) {
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
                                .onAppear {
                                    viewModel.cacheLoadedImage(from: url)
                                }
                        case .failure:
                            ErrorView(message: "图片加载失败")
                                .frame(height: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }

            ResultActionBar(viewModel: viewModel, shareAction: { showingShareSheet = true })
        }
    }

    private func ErrorView(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
    }
}

// MARK: - Result Action Bar

struct ResultActionBar: View {
    @ObservedObject var viewModel: AIGenerateViewModel
    var shareAction: () -> Void = {}

    private let accentBlue = Color(red: 0.2, green: 0.48, blue: 0.95)

    var body: some View {
        HStack(spacing: 0) {
            actionButton(
                icon: "arrow.clockwise",
                title: "重新生成",
                action: { viewModel.regenerate() }
            )

            actionButton(
                icon: "square.and.arrow.up",
                title: "分享",
                action: shareAction
            )

            actionButton(
                icon: viewModel.feedbackRating == 1 ? "hand.thumbsup.fill" : "hand.thumbsup",
                title: "满意",
                isFilled: viewModel.feedbackRating == 1,
                action: { viewModel.submitFeedback(rating: 1) }
            )

            actionButton(
                icon: viewModel.feedbackRating == 0 ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                title: "不满意",
                isFilled: viewModel.feedbackRating == 0,
                action: { viewModel.submitFeedback(rating: 0) }
            )
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
        .padding(.top, 12)
    }

    private func actionButton(icon: String, title: String, isFilled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isFilled ? accentBlue : .secondary)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isFilled ? accentBlue : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - 输入栏组件
struct InputBar: View {
    @ObservedObject var viewModel: AIGenerateViewModel
    @ObservedObject var voiceRecorder: VoiceRecorder

    var onImagePickerRequest: (ImagePicker.SourceType) -> Void

    @State private var isRecording = false
    @State private var longPressTimer: Timer?

    private let accentBlue = Color(red: 0.2, green: 0.48, blue: 0.95)

    var body: some View {
        VStack(spacing: 0) {
            // 语音录制状态提示
            if voiceRecorder.isRecording {
                recordingIndicator
            }

            HStack(spacing: 12) {
                // 图片按钮 - 长按显示菜单
                imagePickerButton

                // 文本输入框
                inputField

                // 发送/麦克风按钮
                actionButton

                // 更多功能按钮
                moreButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.94, green: 0.96, blue: 0.97))
        }
    }

    // MARK: - 子组件

    private var imagePickerButton: some View {
        Menu {
            Button(action: { onImagePickerRequest(.photoLibrary) }) {
                Label("从相册选择", systemImage: "photo.on.rectangle")
            }
            Button(action: { onImagePickerRequest(.camera) }) {
                Label("拍摄照片", systemImage: "camera")
            }
        } label: {
            Image(systemName: "photo")
                .foregroundColor(.secondary)
                .font(.system(size: 20))
        }
    }

    private var inputField: some View {
        HStack(spacing: 8) {
            // 已选图片数量提示
            if !viewModel.selectedImages.isEmpty {
                Image(systemName: "photo.badge.checkmark")
                    .font(.system(size: 14))
                    .foregroundColor(accentBlue)
            }

            TextField("输入描述或按住说话...", text: $viewModel.promptText)
                .font(.system(size: 15))
                .disabled(voiceRecorder.isRecording)

            // 清除按钮
            if !viewModel.promptText.isEmpty {
                Button(action: { viewModel.promptText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(20)
    }

    private var actionButton: some View {
        Group {
            if voiceRecorder.isRecording {
                // 录音中 - 停止按钮
                Button(action: { stopRecording() }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                }
            } else if viewModel.isLoading {
                // 加载中 - 禁用
                ProgressView()
                    .scaleEffect(0.8)
            } else if !viewModel.promptText.isEmpty {
                // 有文本 - 发送按钮
                Button(action: { viewModel.generateImage() }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(accentBlue)
                }
            } else {
                // 无文本 - 麦克风按钮
                Button(action: { startRecording() }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.3)
                        .onChanged { _ in
                            startRecording()
                        }
                        .onEnded { _ in
                            stopRecording()
                        }
                )
            }
        }
    }

    private var moreButton: some View {
        Menu {
            Button(action: {}) {
                Label("历史记录", systemImage: "clock")
            }
            Button(action: {}) {
                Label("我的作品", systemImage: "folder")
            }
            Divider()
            Button(action: {}) {
                Label("设置", systemImage: "gearshape")
            }
        } label: {
            Image(systemName: "plus")
                .foregroundColor(.secondary)
                .font(.system(size: 20))
        }
    }

    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .animation(.pulse.repeatForever(autoreverses: false), value: voiceRecorder.isRecording)

            Text("录音中... \(Int(voiceRecorder.recordingDuration))s")
                .font(.caption)
                .foregroundColor(.secondary)

            if !voiceRecorder.transcribedText.isEmpty {
                Text("\"\(voiceRecorder.transcribedText)\"")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 0.91, green: 0.94, blue: 0.96))
    }

    // MARK: - 录音控制

    private func startRecording() {
        Task {
            let hasPermission = await VoiceRecorder.checkPermission()
            let hasMicPermission = await VoiceRecorder.checkMicrophonePermission()

            if hasPermission && hasMicPermission {
                await MainActor.run {
                    voiceRecorder.startRecording()
                    isRecording = true
                }
            }
        }
    }

    private func stopRecording() {
        voiceRecorder.stopRecording()
        isRecording = false

        // 将语音转文字结果填入输入框
        let transcribedText = voiceRecorder.getTranscribedText()
        if !transcribedText.isEmpty {
            viewModel.promptText = transcribedText
        }
    }
}

// MARK: - 视图模型
class AIGenerateViewModel: ObservableObject {
    /// 用户输入的提示词
    @Published var promptText: String = ""

    /// 生成的图片 URL
    @Published var generatedImageURL: String? = nil

    /// 加载状态
    @Published var isLoading: Bool = false

    /// 加载中的提示文字
    @Published var loadingText: String? = nil

    /// 错误信息
    @Published var errorMessage: String? = nil

    /// 已选择的图片列表
    @Published var selectedImages: [SelectedImage] = []

    /// 用户反馈评分：1=满意，0=不满意，nil=未反馈
    @Published var feedbackRating: Int? = nil

    /// 缓存的生成图片（用于分享）
    @Published var generatedImage: UIImage? = nil

    /// 上次提交的提示词（用于重新生成）
    @Published var lastPrompt: String? = nil

    /// AI 图像服务
    private let client = APIClient.shared

    // MARK: - 图片操作

    /// 添加图片
    func addImage(_ image: UIImage) {
        let selectedImage = SelectedImage(id: UUID(), image: image)
        selectedImages.append(selectedImage)
    }

    /// 移除图片
    func removeImage(_ id: UUID) {
        selectedImages.removeAll { $0.id == id }
    }

    /// 缓存加载完成的图片用于分享
    func cacheLoadedImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.generatedImage = image
            }
        }.resume()
    }

    /// 使用相同的提示词重新生成
    @MainActor
    func regenerate() {
        guard let lastPrompt = lastPrompt else { return }
        promptText = lastPrompt
        feedbackRating = nil
        generatedImage = nil
        generateImage()
    }

    // MARK: - 生成图片

    /// 生成图片
    @MainActor
    func generateImage() {
        // 验证输入
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespaces)
        guard !trimmedPrompt.isEmpty else {
            errorMessage = "请输入描述内容或选择参考图片"
            return
        }

        // 保存提示词用于重新生成
        lastPrompt = trimmedPrompt

        // 重置状态
        isLoading = true
        errorMessage = nil
        generatedImageURL = nil
        loadingText = "正在提交任务..."
        feedbackRating = nil

        // 构建提示词（如果有参考图片，可以添加图片描述）
        var finalPrompt = trimmedPrompt
        if !selectedImages.isEmpty {
            finalPrompt = "\(trimmedPrompt), reference image provided"
        }

        Task {
            do {
                loadingText = "正在提交任务..."
                let url = try await client.generateAndPoll(
                    prompt: finalPrompt,
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
            loadingText = nil
            isLoading = false
        }
    }

    // MARK: - 用户反馈

    /// 提交用户反馈
    @MainActor
    func submitFeedback(rating: Int) {
        feedbackRating = (feedbackRating == rating) ? nil : rating
        // TODO: 上报反馈到后端
        // Task {
        //     await client.submitFeedback(designId: ..., rating: rating)
        // }
    }

    // MARK: - 内部方法

    private func statusText(status: String, progress: Int) -> String {
        switch status {
        case "pending": return "正在排队，请稍候... \(progress)%"
        case "running": return "正在生成苏绣设计... \(progress)%"
        case "succeeded": return "生成完成！"
        default: return "正在生成... \(progress)%"
        }
    }
}

// MARK: - 数据模型
struct SelectedImage: Identifiable, Equatable {
    let id: UUID
    let image: UIImage

    static func == (lhs: SelectedImage, rhs: SelectedImage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 动画扩展
extension Animation {
    static var pulse: Animation {
        .easeInOut(duration: 0.8)
    }
}

#endif
