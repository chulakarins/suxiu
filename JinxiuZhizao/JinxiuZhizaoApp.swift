import SwiftUI

@main
struct JinxiuZhizaoApp: App {
    var body: some Scene {
        WindowGroup {
            rootView
                .preferredColorScheme(.light)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if ProcessInfo.processInfo.arguments.contains("--force-reduce-motion") {
            HomeView()
                .environment(\.suxiuReduceMotionOverride, true)
        } else {
            HomeView()
        }
    }
}
