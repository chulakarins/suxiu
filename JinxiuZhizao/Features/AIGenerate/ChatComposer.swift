#if os(iOS)
import SwiftUI
import UIKit

/// AI 创作页的连续形变输入器。
///
/// 文本区、附件按钮与主操作按钮始终保持同一视图身份；输入区增高时，
/// SwiftUI 只对既有布局做弹簧插值，避免重新挂载导致的光标或按钮闪动。
struct ChatComposer: View {
    @SuxiuReduceMotion private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var viewModel: AIGenerateViewModel
    @ObservedObject var voiceRecorder: VoiceRecorder

    var onImagePickerRequest: (ImagePicker.SourceType) -> Void
    var onDeveloperSettingsRequest: () -> Void
    var onHistoryRequest: () -> Void

    @State private var editorHeight = ComposerMetrics.minimumEditorHeight
    @State private var editorIsFocused = false
    @State private var composerIsHovered = false
    @State private var isRequestingVoicePermission = false
    @State private var voicePermissionTask: Task<Void, Never>?

    private let accentBlue = Color(red: 0.0, green: 0.31, blue: 0.72)
    private let pageBackground = Color(red: 0.94, green: 0.96, blue: 0.97)

    var body: some View {
        composerSurface
            .frame(maxWidth: ComposerMetrics.maximumWidth)
            .padding(.horizontal, ComposerMetrics.outerHorizontalPadding)
            .padding(.top, 9)
            .padding(.bottom, 7)
            .frame(maxWidth: .infinity)
            .background(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        pageBackground.opacity(0),
                        pageBackground.opacity(0.94),
                        pageBackground
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea(.container, edges: .bottom)
                .allowsHitTesting(false)
            }
            .onChange(of: voiceRecorder.isRecording) { _, isRecording in
                if isRecording {
                    editorIsFocused = false
                }
            }
            .onChange(of: viewModel.isLoading) { _, isLoading in
                if isLoading {
                    editorIsFocused = false
                    cancelVoiceInteraction()
                }
            }
            .onDisappear {
                cancelVoiceInteraction()
            }
    }

    private var composerSurface: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsContextActions {
                ComposerContextActions(
                    referenceImageCount: viewModel.selectedImages.count,
                    isRecording: voiceRecorder.isRecording,
                    isRequestingVoicePermission: isRequestingVoicePermission,
                    recordingDuration: voiceRecorder.recordingDuration,
                    transcription: voiceRecorder.transcribedText
                )
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 1)
                .transition(SuxiuMotion.revealTransition(reduceMotion: reduceMotion))
            }

            HStack(alignment: .bottom, spacing: 6) {
                ComposerAttachmentButton(
                    onImagePickerRequest: onImagePickerRequest,
                    onHistoryRequest: onHistoryRequest,
                    onDeveloperSettingsRequest: onDeveloperSettingsRequest
                )

                AutoGrowTextarea(
                    text: $viewModel.promptText,
                    isFocused: $editorIsFocused,
                    measuredHeight: $editorHeight,
                    isEditable: !voiceRecorder.isRecording,
                    placeholder: "输入描述或点击麦克风说话..."
                )
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)

                ComposerSendButton(
                    state: operationState,
                    generationProgress: viewModel.generationProgress,
                    action: performPrimaryAction
                )
            }
            .padding(.horizontal, 7)
            .padding(.top, showsContextActions ? 1 : 7)
            .padding(.bottom, 7)
        }
        .background {
            composerBackground
        }
        .overlay {
            RoundedRectangle(cornerRadius: ComposerMetrics.cornerRadius, style: .continuous)
                .stroke(
                    Color.primary.opacity(editorIsFocused ? 0.10 : composerIsHovered ? 0.075 : 0.045),
                    lineWidth: 0.7
                )
                .animation(SuxiuMotion.composerFocus(reduceMotion: reduceMotion), value: editorIsFocused)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ComposerMetrics.cornerRadius, style: .continuous)
                .stroke(accentBlue.opacity(0.24), lineWidth: 1.4)
                .opacity(editorIsFocused ? 1 : 0)
                .animation(SuxiuMotion.composerFocus(reduceMotion: reduceMotion), value: editorIsFocused)
        }
        .contentShape(RoundedRectangle(cornerRadius: ComposerMetrics.cornerRadius, style: .continuous))
        .onHover { isHovered in
            withAnimation(SuxiuMotion.composerHover(reduceMotion: reduceMotion)) {
                composerIsHovered = isHovered
            }
        }
        .animation(SuxiuMotion.composerMorph(reduceMotion: reduceMotion), value: showsContextActions)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ai-prompt-composer-surface")
    }

    private var composerBackground: some View {
        let shape = RoundedRectangle(
            cornerRadius: ComposerMetrics.cornerRadius,
            style: .continuous
        )
        let surface = Color(uiColor: .systemBackground)
        let tintedShadow = Color(red: 0.16, green: 0.29, blue: 0.43)

        return ZStack {
            shape
                .fill(surface)
                .shadow(
                    color: tintedShadow.opacity(colorScheme == .dark ? 0.22 : 0.08),
                    radius: 12,
                    x: 0,
                    y: 5
                )

            shape
                .fill(surface)
                .shadow(
                    color: tintedShadow.opacity(colorScheme == .dark ? 0.28 : 0.12),
                    radius: 15,
                    x: 0,
                    y: 7
                )
                .opacity(composerIsHovered && !editorIsFocused ? 1 : 0)

            shape
                .fill(surface)
                .shadow(
                    color: accentBlue.opacity(colorScheme == .dark ? 0.30 : 0.16),
                    radius: 19,
                    x: 0,
                    y: 8
                )
                .opacity(editorIsFocused ? 1 : 0)

            shape.fill(surface)

            shape
                .fill(accentBlue.opacity(editorIsFocused ? 0.018 : composerIsHovered ? 0.010 : 0))
        }
        .animation(SuxiuMotion.composerFocus(reduceMotion: reduceMotion), value: editorIsFocused)
    }

    private var showsContextActions: Bool {
        !viewModel.selectedImages.isEmpty
            || voiceRecorder.isRecording
            || isRequestingVoicePermission
    }

    private var hasSendableText: Bool {
        !viewModel.promptText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    private var operationState: ComposerOperationState {
        if viewModel.isLoading { return .generating }
        if voiceRecorder.isRecording { return .recording }
        if isRequestingVoicePermission { return .requestingVoice }
        if hasSendableText { return .send }
        return .voice
    }

    private func performPrimaryAction() {
        switch operationState {
        case .recording:
            stopRecording()
        case .generating:
            viewModel.cancelGeneration()
        case .requestingVoice:
            break
        case .send:
            editorIsFocused = false
            viewModel.generateImage()
        case .voice:
            startRecording()
        }
    }

    private func startRecording() {
        guard !isRequestingVoicePermission else { return }

        editorIsFocused = false
        isRequestingVoicePermission = true

        voicePermissionTask = Task { @MainActor in
            let hasSpeechPermission = await VoiceRecorder.checkPermission()

            guard !Task.isCancelled else {
                isRequestingVoicePermission = false
                voicePermissionTask = nil
                return
            }

            let hasMicrophonePermission = await VoiceRecorder.checkMicrophonePermission()

            isRequestingVoicePermission = false
            voicePermissionTask = nil

            guard !Task.isCancelled else { return }

            guard hasSpeechPermission && hasMicrophonePermission else {
                viewModel.errorMessage = "语音输入需要麦克风和语音识别权限，请在系统设置中允许后重试"
                viewModel.errorFeedbackCount += 1
                return
            }

            viewModel.errorMessage = nil
            voiceRecorder.transcribedText = ""
            voiceRecorder.startRecording()
        }
    }

    private func cancelVoiceInteraction() {
        voicePermissionTask?.cancel()
        voicePermissionTask = nil
        isRequestingVoicePermission = false

        if voiceRecorder.isRecording {
            voiceRecorder.stopRecording()
        }
    }

    private func stopRecording() {
        voiceRecorder.stopRecording()

        let transcribedText = voiceRecorder.getTranscribedText()
        guard !transcribedText.isEmpty else { return }

        withAnimation(SuxiuMotion.composerMorph(reduceMotion: reduceMotion)) {
            viewModel.promptText = transcribedText
        }
    }
}

// MARK: - Composer state

private enum ComposerOperationState: Hashable {
    case voice
    case requestingVoice
    case send
    case recording
    case generating

    var symbolName: String {
        switch self {
        case .voice, .requestingVoice: return "mic.fill"
        case .send: return "arrow.up"
        case .recording, .generating: return "stop.fill"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .voice: return "开始语音输入"
        case .requestingVoice: return "正在开启麦克风"
        case .send: return "开始生成"
        case .recording: return "停止录音"
        case .generating: return "停止生成"
        }
    }
}

private enum ComposerMetrics {
    static let minimumEditorHeight: CGFloat = 23
    static let maximumEditorHeight: CGFloat = 118
    static let cornerRadius: CGFloat = 27
    static let buttonHitSize: CGFloat = 44
    static let buttonVisualSize: CGFloat = 38
    static let maximumWidth: CGFloat = 720
    static let outerHorizontalPadding: CGFloat = 12
}

// MARK: - Attachment

private struct ComposerAttachmentButton: View {
    @SuxiuReduceMotion private var reduceMotion
    @State private var isHovered = false

    var onImagePickerRequest: (ImagePicker.SourceType) -> Void
    var onHistoryRequest: () -> Void
    var onDeveloperSettingsRequest: () -> Void

    var body: some View {
        Menu {
            Button(action: { onImagePickerRequest(.photoLibrary) }) {
                Label("从相册选择", systemImage: "photo.on.rectangle")
            }

            Button(action: { onImagePickerRequest(.camera) }) {
                Label("拍摄照片", systemImage: "camera")
            }

            Divider()

            Button(action: onHistoryRequest) {
                Label("生成历史", systemImage: "clock")
            }

            Button(action: onDeveloperSettingsRequest) {
                Label("Mock 开发设置", systemImage: "gearshape")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(isHovered ? 0.075 : 0.04))
                    .frame(
                        width: ComposerMetrics.buttonVisualSize,
                        height: ComposerMetrics.buttonVisualSize
                    )

                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.primary.opacity(0.70))
            }
            .frame(
                width: ComposerMetrics.buttonHitSize,
                height: ComposerMetrics.buttonHitSize
            )
            .contentShape(Circle())
        }
        .buttonStyle(SuxiuPressStyle(pressedScale: 0.94))
        .onHover { hovering in
            withAnimation(SuxiuMotion.composerHover(reduceMotion: reduceMotion)) {
                isHovered = hovering
            }
        }
        .accessibilityLabel("添加内容")
    }
}

// MARK: - Context actions

private struct ComposerContextActions: View {
    let referenceImageCount: Int
    let isRecording: Bool
    let isRequestingVoicePermission: Bool
    let recordingDuration: Double
    let transcription: String

    var body: some View {
        HStack(spacing: 7) {
            if referenceImageCount > 0 {
                contextChip {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 11, weight: .semibold))
                    Text("\(referenceImageCount) 张参考图")
                }
            }

            if isRecording {
                contextChip {
                    SuxiuActivityDot(color: .red)

                    Text(formattedDuration)
                        .monospacedDigit()

                    Text(transcription.isEmpty ? "正在聆听" : transcription)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(
                            transcription.isEmpty
                                ? Color.secondary
                                : Color(red: 0.0, green: 0.31, blue: 0.72)
                        )
                }
                .layoutPriority(1)
            } else if isRequestingVoicePermission {
                contextChip {
                    Image(systemName: "mic.badge.plus")
                        .font(.system(size: 11, weight: .semibold))
                    Text("正在开启麦克风")
                }
            }

            Spacer(minLength: 0)
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(Color.secondary)
    }

    private var formattedDuration: String {
        let totalSeconds = max(0, Int(recordingDuration))
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private func contextChip<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 6, content: content)
            .padding(.horizontal, 9)
            .frame(height: 28)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.045))
            }
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.primary.opacity(0.045), lineWidth: 0.6)
            }
    }
}

// MARK: - Primary action

private struct ComposerSendButton: View {
    @SuxiuReduceMotion private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    let state: ComposerOperationState
    let generationProgress: Double
    let action: () -> Void

    private let accentBlue = Color(red: 0.0, green: 0.31, blue: 0.72)

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(buttonBackground)

                Circle()
                    .fill(hoverOverlay)
                    .opacity(isHovered ? 1 : 0)

                Image(systemName: state.symbolName)
                    .id(state)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(iconForeground)
                    .transition(SuxiuMotion.composerActionTransition(reduceMotion: reduceMotion))

                if state == .generating {
                    Circle()
                        .trim(
                            from: 0,
                            to: CGFloat(max(0.06, min(generationProgress, 1)))
                        )
                        .stroke(
                            iconForeground.opacity(0.74),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .padding(2.5)
                        .allowsHitTesting(false)
                        .animation(SuxiuMotion.micro(reduceMotion: reduceMotion), value: generationProgress)
                }
            }
            .frame(
                width: ComposerMetrics.buttonVisualSize,
                height: ComposerMetrics.buttonVisualSize
            )
            .frame(
                width: ComposerMetrics.buttonHitSize,
                height: ComposerMetrics.buttonHitSize
            )
            .contentShape(Circle())
        }
        .buttonStyle(SuxiuPressStyle(pressedScale: 0.94))
        .disabled(state == .requestingVoice)
        .opacity(state == .requestingVoice ? 0.62 : 1)
        .onHover { hovering in
            withAnimation(SuxiuMotion.composerHover(reduceMotion: reduceMotion)) {
                isHovered = hovering
            }
        }
        .animation(SuxiuMotion.composerAction(reduceMotion: reduceMotion), value: state)
        .accessibilityLabel(state.accessibilityLabel)
    }

    private var buttonBackground: Color {
        switch state {
        case .voice, .requestingVoice:
            return Color.primary.opacity(isHovered ? 0.09 : 0.055)
        case .send:
            return accentBlue
        case .recording:
            return Color(red: 0.84, green: 0.16, blue: 0.18)
        case .generating:
            return Color(uiColor: .label)
        }
    }

    private var iconForeground: Color {
        switch state {
        case .voice, .requestingVoice:
            return Color.primary.opacity(0.70)
        case .send, .recording:
            return .white
        case .generating:
            return Color(uiColor: .systemBackground)
        }
    }

    private var hoverOverlay: Color {
        switch state {
        case .voice, .requestingVoice:
            return Color.primary.opacity(0.025)
        case .send, .recording, .generating:
            return colorScheme == .dark
                ? Color.black.opacity(0.07)
                : Color.white.opacity(0.09)
        }
    }

    private var iconSize: CGFloat {
        switch state {
        case .voice, .requestingVoice: return 17
        case .send: return 16
        case .recording, .generating: return 13
        }
    }
}

// MARK: - Auto-growing text area

/// 使用 UITextView 获得真实内容高度，并在达到上限后切换为内部滚动。
private struct AutoGrowTextarea: View {
    @SuxiuReduceMotion private var reduceMotion

    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var measuredHeight: CGFloat

    let isEditable: Bool
    let placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            ComposerTextView(
                text: $text,
                isFocused: $isFocused,
                isEditable: isEditable,
                minimumHeight: ComposerMetrics.minimumEditorHeight,
                maximumHeight: ComposerMetrics.maximumEditorHeight,
                onHeightChange: updateHeight
            )

            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.secondary.opacity(0.74))
                    .lineLimit(1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: measuredHeight, alignment: .top)
        .clipped()
        .opacity(isEditable ? 1 : 0.58)
    }

    private func updateHeight(_ newHeight: CGFloat) {
        guard abs(measuredHeight - newHeight) > 0.5 else { return }

        withAnimation(SuxiuMotion.composerMorph(reduceMotion: reduceMotion)) {
            measuredHeight = newHeight
        }
    }
}

private struct ComposerTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    let isEditable: Bool
    let minimumHeight: CGFloat
    let maximumHeight: CGFloat
    let onHeightChange: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> ComposerTextViewContainer {
        let textView = WidthAwareTextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = UIFontMetrics.default.scaledFont(
            for: UIFont.systemFont(ofSize: 16, weight: .regular)
        )
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = .label
        textView.tintColor = UIColor(red: 0.0, green: 0.31, blue: 0.72, alpha: 1)
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.contentInset = .zero
        textView.contentInsetAdjustmentBehavior = .never
        textView.isScrollEnabled = false
        textView.alwaysBounceVertical = false
        textView.alwaysBounceHorizontal = false
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        // 键盘收起只交给页面外层 ScrollView 管理。UITextView 本身也是
        // UIScrollView；若在这里启用 interactive，输入或高度校准引发的
        // 内部 contentOffset 变化会误触发收键盘。保持单一手势管理者可避免
        // Composer 在有、无键盘的两种安全区高度之间切换。
        textView.keyboardDismissMode = .none
        textView.returnKeyType = .default
        textView.autocorrectionType = .yes
        textView.spellCheckingType = .yes
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.accessibilityIdentifier = "ai-prompt-composer"
        textView.accessibilityLabel = "创作描述"
        textView.accessibilityHint = "输入想要生成的苏绣设计描述"
        textView.onWidthChange = { [weak coordinator = context.coordinator] textView in
            coordinator?.scheduleMeasurement(for: textView)
        }
        return ComposerTextViewContainer(textView: textView)
    }

    func updateUIView(_ container: ComposerTextViewContainer, context: Context) {
        context.coordinator.parent = self
        let textView = container.textView

        // 中文输入法存在 marked text 时，UITextView 是唯一可信的编辑源。
        // 此时反向写入 SwiftUI 文本会打断组合态，并可能连带重建输入会话。
        if textView.markedTextRange == nil, textView.text != text {
            textView.text = text
        }

        textView.isEditable = isEditable

        if !isEditable, textView.isFirstResponder {
            textView.resignFirstResponder()
        } else if !isFocused, textView.isFirstResponder {
            textView.resignFirstResponder()
        }

        if context.coordinator.lastMeasuredText != textView.text
            || context.coordinator.lastContentSizeCategory
                != textView.traitCollection.preferredContentSizeCategory {
            context.coordinator.scheduleMeasurement(for: textView)
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: ComposerTextView
        var lastMeasuredText: String?
        var lastContentSizeCategory: UIContentSizeCategory?
        private var measurementIsScheduled = false

        init(parent: ComposerTextView) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if !parent.isFocused {
                parent.isFocused = true
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if parent.isFocused {
                parent.isFocused = false
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            if parent.text != textView.text {
                parent.text = textView.text
            }
            // 用户输入时宽度已经稳定，立即测量可让容器与本次按键处于同一
            // 交互事务中；宽度或动态字体变化仍走异步测量，避开布局重入。
            measure(textView)
            // 某些输入法会在 delegate 回调后才提交最终排版；合并到下一轮
            // 主循环再校准一次，确保快速粘贴和连续换行也不会漏掉高度变化。
            scheduleMeasurement(for: textView)
        }

        func scheduleMeasurement(for textView: UITextView) {
            guard !measurementIsScheduled else { return }
            measurementIsScheduled = true

            DispatchQueue.main.async { [weak self, weak textView] in
                guard let self, let textView else { return }
                self.measurementIsScheduled = false
                self.measure(textView)
            }
        }

        private func measure(_ textView: UITextView) {
            let width = textView.bounds.width
            guard width > 0 else { return }

            let fittingSize = textView.sizeThatFits(
                CGSize(width: width, height: .greatestFiniteMagnitude)
            )
            let naturalHeight = ceil(max(parent.minimumHeight, fittingSize.height))
            let clampedHeight = min(naturalHeight, parent.maximumHeight)
            let shouldScroll = naturalHeight > parent.maximumHeight + 0.5

            lastMeasuredText = textView.text
            lastContentSizeCategory = textView.traitCollection.preferredContentSizeCategory

            if textView.isScrollEnabled != shouldScroll {
                textView.isScrollEnabled = shouldScroll
                textView.alwaysBounceVertical = shouldScroll
                textView.showsVerticalScrollIndicator = shouldScroll
            }

            parent.onHeightChange(clampedHeight)

            if shouldScroll, textView.isFirstResponder {
                textView.scrollRangeToVisible(textView.selectedRange)
            }
        }
    }
}

/// 用一个没有固有高度的容器承接 SwiftUI 给出的动画尺寸，再让文本视图
/// 始终贴合容器边界。这样既保留自然高度测量，也不会让 `UITextView` 的
/// 固有内容尺寸越过 118pt 上限。
private final class ComposerTextViewContainer: UIView {
    let textView: WidthAwareTextView

    init(textView: WidthAwareTextView) {
        self.textView = textView
        super.init(frame: .zero)

        backgroundColor = .clear
        clipsToBounds = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textView)

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class WidthAwareTextView: UITextView {
    var onWidthChange: ((UITextView) -> Void)?
    private var measuredWidth: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()

        guard abs(bounds.width - measuredWidth) > 0.5 else { return }
        measuredWidth = bounds.width
        onWidthChange?(self)
    }
}
#endif
