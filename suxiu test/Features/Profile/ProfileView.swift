import SwiftUI

struct ProfileView: View {
    private let works = ["Work1", "Work2", "Work3", "Work4"]
    private let bgColor = Color(red: 0.93, green: 0.95, blue: 0.97)
    private let accentBlue = Color(red: 0.2, green: 0.48, blue: 0.95)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // 背景色 - 延伸到导航栏下面
                bgColor.ignoresSafeArea(edges: .top)

                // 左上角装饰图 - 1/4 露出
                Image("SuxiuPattern")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .offset(x: -150, y: -150)
                    .opacity(0.8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileHeader
                        statsRow
                            .padding(.top, 22)
                        worksSection
                            .padding(.top, 26)
                        menuSection
                            .padding(.top, 20)
                        Spacer(minLength: 100)
                    }
                }
            }
            #if os(iOS)
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }
            }
            #endif
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 0) {
            // 头像
            ZStack(alignment: .bottomTrailing) {
                Image("ProfileAvatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)

                Circle()
                    .fill(Color(red: 0.18, green: 0.78, blue: 0.35))
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                    .offset(x: 2, y: 2)
            }

            Text("chulakarins")
                .font(.system(size: 19, weight: .bold))
                .padding(.top, 14)

            Text("独立设计师")
                .font(.system(size: 13))
                .foregroundColor(.black)
                .padding(.top, 4)
        }
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(count: "24", label: "我的制作")
            dividerLine
            statItem(count: "12", label: "赞")
            dividerLine
            statItem(count: "6", label: "关注者")
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        // iOS 26 液态玻璃效果
        .glassEffect()
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 1, height: 32)
    }

    private func statItem(count: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(count)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(accentBlue)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Works
    private var worksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("我的作品")
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(works, id: \.self) { name in
                        workCard(name: name)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
        }
    }

    private func workCard(name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: 130, height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
    }

    // MARK: - Menu
    private var menuSection: some View {
        VStack(spacing: 0) {
            menuRow(icon: "bag", title: "我的订单")
            menuRow(icon: "heart", title: "我的收藏")
            menuRow(icon: "clock", title: "历史记录")
        }
        // iOS 26 液态玻璃效果
        .background(.regularMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    private func menuRow(icon: String, title: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(bgColor)
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)

            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 0.5)
                .padding(.leading, 68)
        }
    }
}

#Preview { ProfileView() }
