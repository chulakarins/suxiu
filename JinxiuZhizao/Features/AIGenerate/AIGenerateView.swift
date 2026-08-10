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
    @SuxiuReduceMotion private var reduceMotion
    @StateObject private var viewModel = AIGenerateViewModel()
    @StateObject private var voiceRecorder = VoiceRecorder()
    @Namespace private var briefSelectionNamespace

    @State private var showingImagePicker = false
    @State private var imageSourceType: ImagePicker.SourceType = .photoLibrary
    @State private var showingShareSheet = false
    @State private var showingDeveloperSettings = false
    @State private var showingGenerationHistory = false

    var body: some View {
        GeometryReader { viewport in
            ZStack(alignment: .topLeading) {
                Color(red: 0.94, green: 0.96, blue: 0.97)
                    .ignoresSafeArea(.container, edges: [.top, .bottom])

                // 结果内容与 Composer 使用同一个有限视口。图片高度只影响
                // ScrollView 的内容尺寸，不能再改变 Composer 的屏幕坐标。
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                Spacer().frame(height: 24)

                                Text("AI CREATIVE STUDIO")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.7)
                                    .foregroundColor(Color(red: 0.0, green: 0.31, blue: 0.72))
                                    .padding(.horizontal, 24)

                                Text("把灵感变成可绣的设计")
                                    .font(.system(size: 29, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 24)

                                Text("选择主题、用途与工艺方向，再补充你想表达的故事。")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 24)

                                creativeBriefSection
                                    .padding(.horizontal, 24)
                                    .padding(.top, 10)

                                if !viewModel.selectedImages.isEmpty {
                                    imagePreviewSection
                                        .padding(.horizontal, 24)
                                }

                                // 生成过程与结果共用同一空间，避免重新生成时白屏。
                                generationArea

                                if let error = viewModel.errorMessage {
                                    ErrorView(message: error)
                                        .padding(.horizontal, 24)
                                        .transition(.opacity)
                                }

                                if viewModel.generatedImageURL != nil {
                                    designSpecificationCard
                                        .padding(.horizontal, 24)
                                        .padding(.top, 12)
                                        .opacity(viewModel.isLoading ? 0.55 : 1)
                                        .allowsHitTesting(!viewModel.isLoading)
                                        .transition(
                                            SuxiuMotion.revealTransition(
                                                reduceMotion: reduceMotion
                                            )
                                        )
                                }

                                Spacer(minLength: 24)
                            }
                        }
                        .scrollDismissesKeyboard(.immediately)
                        .accessibilityIdentifier("ai-generation-scroll")
                        .onChange(of: viewModel.successFeedbackCount) { _, _ in
                            withAnimation(SuxiuMotion.resultScroll(reduceMotion: reduceMotion)) {
                                proxy.scrollTo("generation-result", anchor: .top)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)

                    ChatComposer(
                        viewModel: viewModel,
                        voiceRecorder: voiceRecorder,
                        onImagePickerRequest: { sourceType in
                            if sourceType == .camera,
                               !UIImagePickerController.isSourceTypeAvailable(.camera) {
                                viewModel.errorMessage = "当前设备没有可用相机，请从相册选择参考图片"
                                return
                            }
                            imageSourceType = sourceType
                            showingImagePicker = true
                        },
                        onDeveloperSettingsRequest: {
                            showingDeveloperSettings = true
                        },
                        onHistoryRequest: {
                            showingGenerationHistory = true
                        }
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(
                    width: viewport.size.width,
                    height: viewport.size.height,
                    alignment: .top
                )
            }
            .frame(
                width: viewport.size.width,
                height: viewport.size.height,
                alignment: .topLeading
            )
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("AI 生成")
                    .font(.system(size: 17, weight: .semibold))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingGenerationHistory = true }) {
                        Label("生成历史", systemImage: "clock")
                    }
                    Button(action: { showingDeveloperSettings = true }) {
                        Label("Mock 开发设置", systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                        .font(.system(size: 20))
                }
            }
        }
        #endif
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(
                onImageSelected: { image in
                    withAnimation(SuxiuMotion.content(reduceMotion: reduceMotion)) {
                        viewModel.addImage(image)
                    }
                },
                sourceType: imageSourceType
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = viewModel.generatedImage {
                ShareSheet(activityItems: [image])
            }
        }
        .sheet(isPresented: $showingDeveloperSettings, onDismiss: {
            viewModel.reloadMockConfiguration()
        }) {
            DeveloperMockSettingsView()
        }
        .sheet(isPresented: $showingGenerationHistory) {
            GenerationHistoryView()
        }
        .sensoryFeedback(.success, trigger: viewModel.successFeedbackCount)
        .sensoryFeedback(.error, trigger: viewModel.errorFeedbackCount)
        .sensoryFeedback(.warning, trigger: viewModel.cancellationFeedbackCount)
    }

    // MARK: - 子视图

    private var creativeBriefSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("创作简报")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Text("5 项参数")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            briefOptionRow(title: "主题", options: ["花鸟", "山水", "宠物", "纪念"], selection: $viewModel.selectedTheme)
            briefOptionRow(title: "用途", options: ["挂画", "团扇", "胸针", "礼盒"], selection: $viewModel.selectedUsage)
            briefOptionRow(title: "构图", options: ["圆形", "留白", "对称", "长卷"], selection: $viewModel.selectedComposition)
            briefOptionRow(title: "色系", options: ["青绿", "朱砂", "雅灰", "自定义"], selection: $viewModel.selectedPalette)
            briefOptionRow(title: "针法", options: ["智能推荐", "平针绣", "乱针绣", "打籽绣"], selection: $viewModel.selectedStitch)
        }
        .padding(16)
        .background(Color.white.opacity(0.80), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.7), lineWidth: 0.8))
    }

    private func briefOptionRow(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            withAnimation(SuxiuMotion.selection(reduceMotion: reduceMotion)) {
                                selection.wrappedValue = option
                            }
                        }) {
                            Text(option)
                                .font(.system(size: 12, weight: selection.wrappedValue == option ? .semibold : .medium))
                                .foregroundColor(selection.wrappedValue == option ? .white : .primary.opacity(0.68))
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 9)
                                            .fill(Color(red: 0.91, green: 0.94, blue: 0.97))
                                        if selection.wrappedValue == option {
                                            RoundedRectangle(cornerRadius: 9)
                                                .fill(Color(red: 0.0, green: 0.31, blue: 0.72))
                                                .matchedGeometryEffect(
                                                    id: "brief-selection-\(title)",
                                                    in: briefSelectionNamespace
                                                )
                                        }
                                    }
                                }
                        }
                        .buttonStyle(SuxiuPressStyle(pressedScale: 0.96))
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: selection.wrappedValue)
        }
    }

    private var imagePreviewSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.selectedImages, id: \.id) { image in
                    ImagePreview(
                        image: image.image,
                        onRemove: {
                            withAnimation(SuxiuMotion.content(reduceMotion: reduceMotion)) {
                                viewModel.removeImage(image.id)
                            }
                        }
                    )
                    .transition(SuxiuMotion.revealTransition(reduceMotion: reduceMotion))
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var generationArea: some View {
        if let image = viewModel.generatedImage,
           let imageURL = viewModel.generatedImageURL {
            ZStack {
                ResultView(image: image, imageID: imageURL)
                    .id(imageURL)
                    .opacity(viewModel.isLoading ? 0.38 : 1)
                    .allowsHitTesting(!viewModel.isLoading)
                    .transition(SuxiuMotion.revealTransition(reduceMotion: reduceMotion))

                if viewModel.isLoading {
                    generationStatusCard
                        .padding(18)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 24)
            .id("generation-result")
            .animation(SuxiuMotion.reveal(reduceMotion: reduceMotion), value: viewModel.generatedImageURL)
            .animation(SuxiuMotion.content(reduceMotion: reduceMotion), value: viewModel.isLoading)
        } else if viewModel.isLoading {
            generationStatusCard
                .frame(minHeight: 260)
                .padding(.horizontal, 24)
                .transition(SuxiuMotion.revealTransition(reduceMotion: reduceMotion))
        }
    }

    private var generationStatusCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.0, green: 0.31, blue: 0.72).opacity(0.10))
                        .frame(width: 46, height: 46)
                    Image(systemName: viewModel.generationStageIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(red: 0.0, green: 0.31, blue: 0.72))
                        .contentTransition(SuxiuMotion.symbolReplacement(reduceMotion: reduceMotion))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.generationStageTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .contentTransition(SuxiuMotion.textInterpolation(reduceMotion: reduceMotion))
                    Text(viewModel.loadingText ?? "正在准备生成任务")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .contentTransition(SuxiuMotion.textInterpolation(reduceMotion: reduceMotion))
                }
                Spacer(minLength: 8)
                Text("\(Int(viewModel.generationProgress * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.0, green: 0.31, blue: 0.72))
                    .contentTransition(
                        SuxiuMotion.numericTransition(
                            value: viewModel.generationProgress,
                            reduceMotion: reduceMotion
                        )
                    )
            }

            ProgressView(value: viewModel.generationProgress)
                .tint(Color(red: 0.0, green: 0.31, blue: 0.72))

            HStack(spacing: 8) {
                SuxiuActivityDot(color: Color(red: 0.0, green: 0.31, blue: 0.72))
                Text("生成期间可以继续查看当前作品，也可以随时取消")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.62), lineWidth: 0.8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.generationStageTitle)
        .accessibilityValue("完成 \(Int(viewModel.generationProgress * 100)) 百分比")
    }

    private func ResultView(image: UIImage, imageID: URL) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                if viewModel.isMockResult && viewModel.showMockBadge {
                    Text("演示素材")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.62), in: Capsule())
                        .padding(12)
                }
            }
            .id(imageID)

            ResultActionBar(
                viewModel: viewModel,
                regenerateAction: {
                    voiceRecorder.stopRecording()
                    viewModel.regenerate()
                },
                shareAction: { showingShareSheet = true }
            )
        }
    }

    private var designSpecificationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("AI 工艺建议")
                        .font(.system(size: 17, weight: .bold))
                    Text("依据当前创作简报生成 · 比赛演示")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.0, green: 0.58, blue: 0.48))
            }

            Divider()
            specificationRow(icon: "scribble.variable", title: "推荐针法", value: viewModel.recommendedStitch)
            specificationRow(icon: "paintpalette", title: "丝线色卡", value: viewModel.recommendedColors)
            specificationRow(icon: "gauge.with.dots.needle.67percent", title: "制作难度", value: "中等 · 3/5")
            specificationRow(icon: "clock", title: "预计工时", value: "约 36–48 小时")
            specificationRow(icon: "ruler", title: "建议尺寸", value: viewModel.selectedUsage == "团扇" ? "直径 22 cm" : "画芯 30 × 30 cm")
        }
        .padding(16)
        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 20))
    }

    private func specificationRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.0, green: 0.31, blue: 0.72))
                .frame(width: 22)
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
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
    @SuxiuReduceMotion private var reduceMotion
    @ObservedObject var viewModel: AIGenerateViewModel
    var regenerateAction: () -> Void
    var shareAction: () -> Void = {}

    private let accentBlue = Color(red: 0.2, green: 0.48, blue: 0.95)

    var body: some View {
        HStack(spacing: 0) {
            actionButton(
                icon: "arrow.clockwise",
                title: "重新生成",
                action: regenerateAction
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
        .animation(SuxiuMotion.selection(reduceMotion: reduceMotion), value: viewModel.feedbackRating)
        .sensoryFeedback(.selection, trigger: viewModel.feedbackRating)
    }

    private func actionButton(icon: String, title: String, isFilled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isFilled ? accentBlue : .secondary)
                    .contentTransition(SuxiuMotion.symbolReplacement(reduceMotion: reduceMotion))
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isFilled ? accentBlue : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(SuxiuPressStyle(pressedScale: 0.94))
    }
}

// MARK: - 视图模型
@MainActor
class AIGenerateViewModel: ObservableObject {
    /// 用户输入的提示词
    @Published var promptText: String = ""

    /// 保存到 Application Support 后的本地图片 URL
    @Published var generatedImageURL: URL? = nil

    /// 加载状态
    @Published var isLoading: Bool = false

    /// 加载中的提示文字
    @Published var loadingText: String? = nil

    /// 供界面连续展示的结构化阶段与总体进度。
    @Published var generationStage: GenerationStage = .idle
    @Published var generationProgress: Double = 0

    /// 错误信息
    @Published var errorMessage: String? = nil

    /// 已选择的图片列表
    @Published var selectedImages: [SelectedImage] = []

    /// 用户反馈评分：1=满意，0=不满意，nil=未反馈
    @Published var feedbackRating: Int? = nil

    /// 语义触觉反馈触发器。使用计数器避免同一状态反复触发。
    @Published var successFeedbackCount = 0
    @Published var errorFeedbackCount = 0
    @Published var cancellationFeedbackCount = 0

    /// 缓存的生成图片（用于分享）
    @Published var generatedImage: UIImage? = nil

    /// 当前结果是否来自 Mock 服务
    @Published var isMockResult = false

    /// 是否显示演示素材标记
    @Published var showMockBadge = AppEnvironment.shouldShowMockBadge

    /// 上次提交的提示词（用于重新生成）
    @Published var lastPrompt: String? = nil

    /// 结构化创作简报
    @Published var selectedTheme: String = "花鸟"
    @Published var selectedUsage: String = "挂画"
    @Published var selectedComposition: String = "圆形"
    @Published var selectedPalette: String = "青绿"
    @Published var selectedStitch: String = "智能推荐"

    var recommendedStitch: String {
        selectedStitch == "智能推荐" ? (selectedTheme == "宠物" ? "乱针绣 + 施针" : "平针绣 + 套针") : selectedStitch
    }

    var recommendedColors: String {
        switch selectedPalette {
        case "朱砂": return "朱砂红 · 胭脂 · 米白"
        case "雅灰": return "月白 · 烟灰 · 藕荷"
        case "自定义": return "从参考图提取 6 色"
        default: return "石青 · 竹青 · 月白"
        }
    }

    var generationStageTitle: String {
        switch generationStage {
        case .idle: return "准备创作"
        case .validating: return "检查创作内容"
        case .queued: return "等待生成"
        case .generating: return "绣制数字样稿"
        case .downloading: return "获取生成结果"
        case .saving: return "保存作品"
        case .completed: return "生成完成"
        case .failed: return "生成未完成"
        case .cancelled: return "已取消生成"
        }
    }

    var generationStageIcon: String {
        switch generationStage {
        case .idle, .validating: return "checkmark.shield"
        case .queued: return "clock"
        case .generating: return "scribble.variable"
        case .downloading: return "arrow.down.circle"
        case .saving: return "square.and.arrow.down"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle"
        }
    }

    /// 可替换的图像服务与统一存储层
    private var imageGenerator: any ImageGenerating
    private let fileStore: GeneratedFileStore
    private let repository: GenerationRepository
    private var generationTask: Task<Void, Never>?

    init() {
        self.imageGenerator = AppEnvironment.makeImageGenerator()
        self.fileStore = .shared
        self.repository = .shared
    }

    init(
        imageGenerator: any ImageGenerating,
        fileStore: GeneratedFileStore,
        repository: GenerationRepository
    ) {
        self.imageGenerator = imageGenerator
        self.fileStore = fileStore
        self.repository = repository
    }

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

    func reloadMockConfiguration() {
        imageGenerator = AppEnvironment.makeImageGenerator()
        showMockBadge = AppEnvironment.shouldShowMockBadge
    }

    /// 使用相同的提示词重新生成
    @MainActor
    func regenerate() {
        guard let lastPrompt = lastPrompt else { return }
        promptText = lastPrompt
        feedbackRating = nil
        generateImage()
    }

    // MARK: - 生成图片

    /// 生成图片
    @MainActor
    func generateImage() {
        // 验证输入
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            errorMessage = "请输入描述内容"
            errorFeedbackCount += 1
            return
        }

        // 保存提示词用于重新生成
        lastPrompt = trimmedPrompt

        // 重置状态
        isLoading = true
        errorMessage = nil
        loadingText = "正在提交任务..."
        generationStage = .validating
        generationProgress = 0.03
        feedbackRating = nil

        // 构建提示词（如果有参考图片，可以添加图片描述）
        var finalPrompt = "\(trimmedPrompt)，主题：\(selectedTheme)，用途：\(selectedUsage)，\(selectedComposition)构图，\(selectedPalette)色系，建议采用\(recommendedStitch)"
        if !selectedImages.isEmpty {
            finalPrompt = "\(trimmedPrompt), reference image provided"
        }

        let recordID: UUID
        do {
            recordID = try repository.createPending(prompt: trimmedPrompt)
        } catch {
            isLoading = false
            loadingText = nil
            generationStage = .failed
            generationProgress = 0
            errorMessage = "无法创建生成记录，请稍后重试"
            errorFeedbackCount += 1
            return
        }

        let referenceData = selectedImages.first?.image.jpegData(compressionQuality: 0.9)
        let generator = imageGenerator

        generationTask = Task { [weak self] in
            guard let self else { return }
            var savedRelativePath: String?
            do {
                let payload = try await generator.generate(
                    prompt: finalPrompt,
                    referenceImageData: referenceData,
                    onProgress: { [weak self] stage in
                        await self?.handleProgress(stage, recordID: recordID)
                    }
                )

                let decodedImage = await Task.detached(priority: .userInitiated) {
                    UIImage(data: payload.imageData)
                }.value
                guard let decodedImage else {
                    throw GenerationError.invalidResponse
                }

                handleProgress(.saving, recordID: recordID)
                let relativePath = try await fileStore.save(
                    data: payload.imageData,
                    fileExtension: payload.fileExtension,
                    id: recordID
                )
                savedRelativePath = relativePath
                let localURL = try await fileStore.url(for: relativePath)
                try repository.complete(
                    id: recordID,
                    payload: payload,
                    localImagePath: relativePath
                )
                savedRelativePath = nil

                generatedImage = decodedImage
                generatedImageURL = localURL
                isMockResult = payload.isMock
                loadingText = "生成完成！"
                handleProgress(.completed, recordID: recordID)
                successFeedbackCount += 1
            } catch is CancellationError {
                if let savedRelativePath {
                    try? await fileStore.delete(relativePath: savedRelativePath)
                }
                try? repository.update(id: recordID, stage: .cancelled)
                errorMessage = nil
                loadingText = "已取消生成"
                generationStage = .cancelled
                cancellationFeedbackCount += 1
            } catch {
                if let savedRelativePath {
                    try? await fileStore.delete(relativePath: savedRelativePath)
                }
                try? repository.fail(id: recordID, error: error)
                errorMessage = error.localizedDescription
                generationStage = .failed
                errorFeedbackCount += 1
            }
            try? await Task.sleep(for: .milliseconds(250))
            if !Task.isCancelled {
                loadingText = nil
            }
            isLoading = false
            generationTask = nil
        }
    }

    func cancelGeneration() {
        generationTask?.cancel()
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

    private func handleProgress(_ stage: GenerationStage, recordID: UUID) {
        try? repository.update(id: recordID, stage: stage)
        generationStage = stage

        switch stage {
        case .idle:
            loadingText = nil
            generationProgress = 0
        case .validating:
            loadingText = "正在检查创作内容..."
            generationProgress = 0.04
        case .queued:
            loadingText = "正在排队，请稍候..."
            generationProgress = 0.12
        case .generating(let progress):
            loadingText = "正在生成苏绣设计..."
            generationProgress = 0.15 + min(max(progress, 0), 1) * 0.65
        case .downloading:
            loadingText = "正在获取生成结果..."
            generationProgress = 0.86
        case .saving:
            loadingText = "正在保存作品..."
            generationProgress = 0.94
        case .completed:
            loadingText = "生成完成！"
            generationProgress = 1
        case .failed:
            loadingText = nil
        case .cancelled:
            loadingText = "已取消生成"
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

#endif
