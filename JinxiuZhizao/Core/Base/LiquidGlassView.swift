import SwiftUI

// MARK: - Liquid Glass Modifiers
//
// 遵循 iOS 26 Liquid Glass 设计规范：
// - 修饰符顺序：先布局/外观，后 glassEffect
// - iOS 26+ 使用原生 glassEffect，旧版降级为 ultraThinMaterial
// - 形状通过 glassEffect(in:) 指定，不使用外部 cornerRadius
// - 交互元素使用 .interactive() 增强反馈

extension View {

    /// 液态玻璃效果 - Tab Bar、大面板
    /// iOS 26+ 原生 glassEffect(.regular)，旧版降级 ultraThinMaterial
    @ViewBuilder
    func liquidGlass(cornerRadius: CGFloat = 45) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }

    /// 轻量液态玻璃 - 输入框等小型组件
    @ViewBuilder
    func liquidGlassThin(cornerRadius: CGFloat = 22) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        }
    }

    /// 增强液态玻璃 - 卡片等需要更强质感的场景
    @ViewBuilder
    func liquidGlassProminent(cornerRadius: CGFloat = 16) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        }
    }

    /// 可交互液态玻璃 - 按钮等需要触控反馈的元素
    /// 使用 .interactive() 提供触控和指针交互反馈
    @ViewBuilder
    func liquidGlassInteractive(cornerRadius: CGFloat = 16) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Competition-ready Liquid Glass Components

/// iOS 26 悬浮导航使用的统一玻璃表面。
/// 将折射边缘、高光与阴影集中管理，避免各页面重复堆叠材质。
extension View {
    @ViewBuilder
    func suxiuFloatingGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: shape)
                .overlay {
                    shape
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.78), .white.opacity(0.16)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                }
                .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.40).opacity(0.14), radius: 22, x: 0, y: 12)
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                }
                .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.40).opacity(0.14), radius: 22, x: 0, y: 12)
        }
    }

    /// AI 主入口使用的带品牌色液态玻璃。
    @ViewBuilder
    func suxiuTintedGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.tint(Color(red: 0.0, green: 0.31, blue: 0.72)).interactive(), in: shape)
                .overlay {
                    shape.stroke(Color.white.opacity(0.42), lineWidth: 0.8)
                }
        } else {
            self
                .background(Color(red: 0.0, green: 0.31, blue: 0.72), in: shape)
                .overlay {
                    shape.stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                }
        }
    }
}
