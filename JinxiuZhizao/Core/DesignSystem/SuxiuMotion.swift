import SwiftUI

private struct SuxiuReduceMotionOverrideKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var suxiuReduceMotionOverride: Bool {
        get { self[SuxiuReduceMotionOverrideKey.self] }
        set { self[SuxiuReduceMotionOverrideKey.self] = newValue }
    }
}

/// 正式运行读取系统 Reduce Motion；测试可额外开启内部 override。
@propertyWrapper
struct SuxiuReduceMotion: DynamicProperty {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.suxiuReduceMotionOverride) private var override

    var wrappedValue: Bool {
        systemReduceMotion || override
    }
}

/// 锦绣智造的语义动效系统。
///
/// 页面只描述“选择、内容变化、结果出现”等意图，不直接散写动画参数。
enum SuxiuMotion {
    static func micro(reduceMotion: Bool) -> Animation? {
        reduceMotion ? .easeOut(duration: 0.08) : .easeOut(duration: 0.14)
    }

    static func selection(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .snappy(duration: 0.24, extraBounce: 0.02)
    }

    static func content(reduceMotion: Bool) -> Animation? {
        reduceMotion ? .easeOut(duration: 0.12) : .smooth(duration: 0.30)
    }

    /// 结果定位属于空间位移；Reduce Motion 下必须直接跳转。
    static func resultScroll(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .smooth(duration: 0.30)
    }

    static func reveal(reduceMotion: Bool) -> Animation? {
        reduceMotion ? .easeOut(duration: 0.12) : .spring(duration: 0.38, bounce: 0.08)
    }

    static func compare(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.28)
    }

    /// Composer 指针悬停与轻量表面反馈：不改变几何尺寸。
    static func composerHover(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.17)
    }

    /// Composer 获得焦点时的克制弹簧；参数对应约 330 stiffness / 30 damping。
    static func composerFocus(reduceMotion: Bool) -> Animation? {
        reduceMotion
            ? .easeOut(duration: 0.10)
            : .interpolatingSpring(mass: 0.82, stiffness: 330, damping: 30, initialVelocity: 0)
    }

    /// 文本区域增高、附件上下文出现时使用的统一布局弹簧。
    static func composerMorph(reduceMotion: Bool) -> Animation? {
        reduceMotion
            ? nil
            : .interpolatingSpring(mass: 0.78, stiffness: 360, damping: 30, initialVelocity: 0)
    }

    /// 发送、语音和停止状态之间的快速替换。
    static func composerAction(reduceMotion: Bool) -> Animation? {
        reduceMotion
            ? .easeOut(duration: 0.10)
            : .interpolatingSpring(mass: 0.66, stiffness: 420, damping: 30, initialVelocity: 0)
    }

    static func composerActionTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.78).combined(with: .opacity)
    }

    static func directionalTransition(
        forward: Bool,
        reduceMotion: Bool,
        distance: CGFloat = 12
    ) -> AnyTransition {
        guard !reduceMotion else { return .opacity }

        return .asymmetric(
            insertion: .offset(x: forward ? distance : -distance).combined(with: .opacity),
            removal: .offset(x: forward ? -distance : distance).combined(with: .opacity)
        )
    }

    static func revealTransition(reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .scale(scale: 0.985).combined(with: .opacity)
    }

    static func symbolReplacement(reduceMotion: Bool) -> ContentTransition {
        reduceMotion ? .identity : .symbolEffect(.replace)
    }

    static func textInterpolation(reduceMotion: Bool) -> ContentTransition {
        reduceMotion ? .identity : .interpolate
    }

    static func numericTransition(reduceMotion: Bool) -> ContentTransition {
        reduceMotion ? .identity : .numericText()
    }

    static func numericTransition(value: Double, reduceMotion: Bool) -> ContentTransition {
        reduceMotion ? .identity : .numericText(value: value)
    }
}

/// 自定义卡片与图标按钮的统一按压反馈。
struct SuxiuPressStyle: ButtonStyle {
    @SuxiuReduceMotion private var reduceMotion

    var pressedScale: CGFloat = 0.98
    var pressedOpacity: Double = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? pressedScale : 1)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(SuxiuMotion.micro(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

/// Reduce Motion 开启时保持静止；否则由合成层插值，避免逐帧刷新视图树。
struct SuxiuActivityDot: View {
    @SuxiuReduceMotion private var reduceMotion
    @State private var isExpanded = false
    var color: Color = .red

    var body: some View {
        dot(
            scale: reduceMotion ? 1 : isExpanded ? 1 : 0.84,
            opacity: reduceMotion ? 1 : isExpanded ? 1 : 0.58
        )
        // 无限动画必须严格留在圆点自身的渲染层。若从 `withAnimation`
        // 启动 repeating transaction，生成完成时同一轮视图更新里的键盘
        // safe-area 与父布局也可能继承它，造成整页按脉冲周期往返重排。
        .animation(
            reduceMotion
                ? nil
                : .easeInOut(duration: 0.575).repeatForever(autoreverses: true),
            value: isExpanded
        )
        .onAppear {
            isExpanded = !reduceMotion
        }
        .onChange(of: reduceMotion) { _, shouldReduceMotion in
            isExpanded = !shouldReduceMotion
        }
    }

    private func dot(scale: Double, opacity: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .opacity(opacity)
    }
}
