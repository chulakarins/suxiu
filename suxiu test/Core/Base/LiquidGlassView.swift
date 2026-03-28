import SwiftUI

// iOS 26 原生 Liquid Glass 自动适配
// NavigationStack / NavigationSplitView / UINavigationBar 会自动应用液态玻璃效果
// 仅用于自定义组件的液态玻璃效果（如 Tab Bar、输入框、卡片等）

extension View {
    /// 液态玻璃效果 - 用于 Tab Bar、卡片等自定义组件
    /// iOS 26+ 使用 .glassEffect()
    func liquidGlass(cornerRadius: CGFloat = 45) -> some View {
        self
            .glassEffect()
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    /// 轻量液态玻璃 - 用于输入框等小型组件
    func liquidGlassThin(cornerRadius: CGFloat = 22) -> some View {
        self
            .glassEffect()
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
    }

    /// 增强液态玻璃 - 用于卡片等需要更强质感的场景
    func liquidGlassProminent(cornerRadius: CGFloat = 16) -> some View {
        self
            .glassEffect()
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
    }
}
