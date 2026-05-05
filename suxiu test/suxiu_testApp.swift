import SwiftUI

@main
struct SuXiuAIApp: App {
    @State private var isAuthenticated: Bool = false
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    HomeView()
                } else {
                    AuthView(viewModel: authViewModel) {
                        isAuthenticated = true
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isAuthenticated)
            .preferredColorScheme(.light)
            .onAppear {
                if authViewModel.isAuthenticated {
                    isAuthenticated = true
                }
            }
            .onReceive(authViewModel.$isAuthenticated) { authenticated in
                if authenticated {
                    isAuthenticated = true
                }
            }
        }
    }
}
