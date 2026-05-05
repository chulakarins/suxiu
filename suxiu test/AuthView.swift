import SwiftUI
import Combine

// MARK: - AuthViewModel

/// 认证视图模型 - 管理登录/注册流程
class AuthViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isAuthenticated: Bool = false

    private let client = APIClient.shared

    init() {
        // 检查本地是否已有有效 token
        isAuthenticated = client.isLoggedIn
    }

    /// 登录或注册（自动判断）
    @MainActor
    func loginOrRegister() {
        let trimmedUser = username.trimmingCharacters(in: .whitespaces)
        guard !trimmedUser.isEmpty else {
            errorMessage = "请输入用户名"
            return
        }
        guard password.count >= 8 else {
            errorMessage = "密码至少 8 位"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await client.autoAuth(username: trimmedUser, password: password)
                isAuthenticated = true
                print("[Auth] 登录成功：\(result.username)")
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    /// 退出登录
    func logout() {
        client.clearTokens()
        isAuthenticated = false
        username = ""
        password = ""
    }
}

// MARK: - AuthView

/// 登录/注册页面 - 输入用户名密码自动登录或注册
struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    var onAuthenticated: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 背景色
            Color(red: 0.91, green: 0.94, blue: 0.96)
                .ignoresSafeArea(edges: .top)

            // 左上角装饰
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(Color(red: 0.2, green: 0.48, blue: 0.95).opacity(0.15))
                .offset(x: -50, y: -30)

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                // Logo 区域
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 64))
                        .foregroundColor(Color(red: 0.2, green: 0.48, blue: 0.95))

                    Text("锦绣AI")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)

                    Text("AI 苏绣设计生成")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 50)

                // 登录表单
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("用户名")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("", text: $viewModel.username)
                            .font(.system(size: 16))
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("密码")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        SecureField("", text: $viewModel.password)
                            .font(.system(size: 16))
                            .textContentType(.password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }

                    Button(action: { viewModel.loginOrRegister() }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20))
                            }
                            Text(viewModel.isLoading ? "登录中..." : "登录 / 注册")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 0.2, green: 0.48, blue: 0.95))
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(viewModel.isLoading)

                    Text("输入用户名和密码，自动登录或注册")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)
            }
        }
    }
}
