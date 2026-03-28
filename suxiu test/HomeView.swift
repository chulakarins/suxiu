import SwiftUI
import PhotosUI
#if os(iOS)
import UIKit
#endif

/// 首页视图 - 应用主界面
///
/// 功能：
/// - 底部悬浮 Tab Bar 导航（液态玻璃效果）
/// - 首页：AI 图片生成主界面
/// - 市场：浏览和购买作品
/// - 推荐：推荐内容
/// - 我的：个人页面
/// - 中间魔法按钮：快速生成图片
struct HomeView: View {
    /// 输入框文本 - 用户输入的提示词
    @State private var promptText: String = ""

    /// 选中的 Tab 索引 (0=首页，1=市场，2=推荐，3=我的)
    @State private var selectedTab: Int = 0

    /// 是否正在生成图片
    @State private var isGenerating = false

    /// 生成的图片 URL
    @State private var generatedImageURL: String?

    /// 是否显示错误
    @State private var showError = false

    /// 错误信息
    @State private var errorMessage = ""

    /// AI 图像服务实例
    private let aiService = AIImageService()

    // MARK: - Image Picker State

    /// 选中的图片
    @State private var selectedImage: UIImage?

    /// 显示图片选择器
    @State private var showImagePicker = false

    /// 选中的 PHPicker 项目
    @State private var pickerItem: PhotosPickerItem?

    // MARK: - Voice Recording State

    /// 是否正在录音
    @State private var isRecording = false

    /// 录音会话
    @StateObject private var voiceRecorder = VoiceRecorder()

    /// 背景色 - 浅蓝灰色
    private let bgColor = Color(red: 0.93, green: 0.95, blue: 0.97)

    /// 强调色 - 蓝色
    private let accentBlue = Color(red: 0.2, green: 0.48, blue: 0.95)

    // MARK: - Layout Constants

    /// Tab Bar 高度：56pt
    private let tabBarHeight: CGFloat = 56

    /// Home Indicator 高度：12pt
    private let homeIndicatorHeight: CGFloat = 12

    /// Tab Bar 总高度（Tab Bar + Home Indicator）
    private let tabBarTotalHeight: CGFloat = 68 // 56 + 12

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 全屏背景 - 延伸到导航栏下面
                bgColor.ignoresSafeArea(edges: .top)

                // 内容层 - 根据选中的 Tab 切换
                Group {
                    if selectedTab == 4 {
                        ProfileView()
                    } else {
                        mainScrollArea
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 底部液态玻璃 Tab Bar - 悬浮效果
                VStack(spacing: 0) {
                    if selectedTab != 4 {
                        inputBar
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }
                    liquidTabBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, homeIndicatorHeight)
                }
                .padding(.bottom, 0) // 额外底部 padding 已包含在 homeIndicatorHeight 中
            }
            .ignoresSafeArea(edges: .bottom)
            #if os(iOS)
            .navigationTitle("锦绣 AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image("ProfileAvatar")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    }
                }
            }
            #endif
            .alert("错误", isPresented: $showError) {
                Button("确定") { showError = false }
            } message: {
                Text(errorMessage)
            }
        }
    }


    // MARK: - Liquid Tab Bar
    private var liquidTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "house", label: "首页", tag: 0)
            tabItem(icon: "bag", label: "市场", tag: 1)

            // 中间魔法按钮
            Button(action: {
                selectedTab = 2
                if !promptText.isEmpty { sendMessage() }
            }) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [accentBlue, Color(red: 0.1, green: 0.35, blue: 0.9)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                        .shadow(color: accentBlue.opacity(0.45), radius: 12, x: 0, y: 4)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    Image(systemName: isGenerating ? "hourglass" : "wand.and.stars")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isGenerating ? 360 : 0))
                        .animation(isGenerating ? .linear(duration: 1.2).repeatForever(autoreverses: false) : .default, value: isGenerating)
                }
            }
            .frame(maxWidth: .infinity)
            .disabled(isGenerating)

            tabItem(icon: "doc.text", label: "推荐", tag: 3)
            tabItem(icon: "person", label: "我的", tag: 4)
        }
        .frame(height: tabBarHeight) // 固定 Tab Bar 高度为 56pt
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .glassEffect()
        .cornerRadius(45)
        .overlay(
            RoundedRectangle(cornerRadius: 45)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private func tabItem(icon: String, label: String, tag: Int) -> some View {
        Button(action: { withAnimation(.spring(response: 0.3)) { selectedTab = tag } }) {
            VStack(spacing: 3) {
                Image(systemName: selectedTab == tag ? "\(icon).fill" : icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == tag ? accentBlue : .black.opacity(0.5))
                    .scaleEffect(selectedTab == tag ? 1.08 : 1.0)
                Text(label)
                    .font(.system(size: 10, weight: selectedTab == tag ? .semibold : .regular))
                    .foregroundColor(selectedTab == tag ? accentBlue : .black.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
        }
        .animation(.spring(response: 0.25), value: selectedTab)
    }

    // MARK: - Main Scroll
    private var mainScrollArea: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // 顶部留白（导航栏高度 + margin）
                Spacer().frame(height: 120)

                // 装饰图
                ZStack(alignment: .topLeading) {
                    Color.clear.frame(height: 160)
                    Image("SuxiuPattern")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                        .offset(x: -150, y: -80)
                        .opacity(0.72)
                }

                // 主文案
                VStack(alignment: .leading, spacing: 8) {
                    Text("输入您的创意想法")
                        .font(.system(size: 15))
                        .foregroundColor(.black.opacity(0.55))
                    Text("AI 将为您生成设计图案")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                if isGenerating {
                    generatingPlaceholder
                        .padding(.top, 32)
                        .padding(.horizontal, 24)
                }

                if let url = generatedImageURL {
                    generatedResult(url: url)
                        .padding(.top, 28)
                        .padding(.horizontal, 24)
                }

                // 底部留白（输入栏 + tab bar 高度）
                Spacer(minLength: 180)
            }
        }
        .onTapGesture { hideKeyboard() }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Generating Placeholder
    private var generatingPlaceholder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.5))
            .frame(height: 280)
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(accentBlue)
                    Text("正在生成苏绣图案...")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.6))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    // MARK: - Generated Result
    private func generatedResult(url: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("生成结果")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                Button {
                    withAnimation(.spring()) { generatedImageURL = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.black.opacity(0.3))
                }
            }
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFit()
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                case .failure:
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.system(size: 32))
                                    .foregroundColor(.black.opacity(0.4))
                                Text("图片加载失败")
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.4))
                            }
                        )
                case .empty:
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.5))
                        .frame(height: 280)
                        .overlay(ProgressView().tint(accentBlue))
                @unknown default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Input Bar (liquid glass)
    private var inputBar: some View {
        HStack(spacing: 10) {
            // 图片按钮
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Image(systemName: "photo")
                    .font(.system(size: 17))
                    .foregroundColor(.black.opacity(0.5))
                    .frame(width: 36, height: 36)
            }
            .onChange(of: pickerItem) { oldItem, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        showImagePicker = true
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("完成") {
                                    selectedImage = nil
                                    showImagePicker = false
                                }
                            }
                        }
                }
            }

            HStack(spacing: 8) {
                TextField("发消息或按住说话...", text: $promptText)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .disabled(isGenerating)
                    .onSubmit { sendMessage() }

                if isGenerating {
                    ProgressView().scaleEffect(0.75).tint(accentBlue)
                } else if !promptText.isEmpty {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(accentBlue)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect()
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )

            // 语音按钮 - 长按录音
            Button(action: {
                voiceRecorder.stopRecording()
                withAnimation(.spring(response: 0.15)) {
                    isRecording = false
                }
                // 停止录音后，将语音转文字结果填入输入框
                let text = voiceRecorder.getTranscribedText()
                if !text.isEmpty {
                    promptText = text
                }
            }) {
                Image(systemName: isRecording ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 17))
                    .foregroundColor(isRecording ? .red : .black.opacity(0.5))
                    .frame(width: 36, height: 36)
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.3)
                    .onChanged { _ in
                        withAnimation(.spring(response: 0.15)) {
                            isRecording = true
                        }
                        voiceRecorder.startRecording()
                    }
            )

            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 17))
                    .foregroundColor(.black.opacity(0.5))
                    .frame(width: 36, height: 36)
            }
        }
        .animation(.spring(response: 0.3), value: promptText.isEmpty)
    }

    // MARK: - Actions
    private func sendMessage() {
        guard !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isGenerating else { return }
        let prompt = promptText
        isGenerating = true
        Task {
            do {
                let url = try await aiService.generateSuxiuImageURL(prompt: prompt)
                await MainActor.run {
                    withAnimation { generatedImageURL = url }
                    isGenerating = false
                    promptText = ""
                    hideKeyboard()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = "生成失败：\(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    private func hideKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

// 保留兼容性
struct TabBarItem: View {
    let icon: String; let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 21))
                    .foregroundColor(isSelected ? Color(red: 0.2, green: 0.48, blue: 0.95) : .black.opacity(0.5))
                Text(title).font(.system(size: 10))
                    .foregroundColor(isSelected ? Color(red: 0.2, green: 0.48, blue: 0.95) : .black.opacity(0.5))
            }.frame(maxWidth: .infinity)
        }
    }
}

#Preview { HomeView() }
