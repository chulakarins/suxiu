import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ExploreHomeView
/// 探索首页视图 - 展示苏绣文化遗产内容
struct ExploreHomeView: View {
    @State private var selectedCategory: Int = 0
    private let bgColor = Color(red: 0.98, green: 0.97, blue: 0.95)
    private let accentGreen = Color(red: 0.0, green: 0.75, blue: 0.53)
    private let suxiuBlue = Color(hex: "004FB8")

    private let categories = [
        (name: "LiveStudio", label: "Live Studio"),
        (name: "Materials", label: "Materials"),
        (name: "Patterns", label: "Patterns"),
        (name: "Masters", label: "Masters"),
        (name: "Archives", label: "Archives")
    ]

    var onAICardTap: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: -15)

                categoryScrollView.padding(.vertical, 16)

                communityHeader
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                contentCard
                    .padding(.horizontal, 20)

                aiFeatureCard
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Spacer(minLength: 20)
            }
        }
    }

    private var categoryScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<categories.count, id: \.self) { index in
                    categoryItem(
                        name: categories[index].name,
                        label: categories[index].label,
                        isSelected: selectedCategory == index
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25)) { selectedCategory = index }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func categoryItem(name: String, label: String, isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(bgColor)
                    .frame(width: 64, height: 64)

                #if os(iOS)
                if UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.black.opacity(0.5))
                        .frame(width: 64, height: 64)
                }
                #else
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.black.opacity(0.5))
                    .frame(width: 64, height: 64)
                #endif

                if isSelected {
                    Circle()
                        .stroke(accentGreen, lineWidth: 3)
                        .frame(width: 64, height: 64)
                }
            }

            Text(label)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .black : .black.opacity(0.5))
                .lineLimit(1)
        }
    }

    private var communityHeader: some View {
        HStack {
            Text("社群")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            Spacer()
            Text("精选")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
        }
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            #if os(iOS)
            if UIImage(named: "CommunityCard") != nil {
                Image("CommunityCard")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipped()
            } else {
                placeholderImage
            }
            #else
            placeholderImage
            #endif

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(suxiuBlue)
                            .frame(width: 40, height: 40)
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI-Powered Restoration")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)

                        Text("Upload a faded heritage piece to see it reimagined through AI-simulated Su embroidery techniques.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.black.opacity(0.6))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }

                HStack(spacing: 4) {
                    Text("Try Customizer")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(suxiuBlue)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(suxiuBlue)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(suxiuBlue.opacity(0.08))
                    .blur(radius: 0)
            )
            .padding(.top, -1)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .overlay(
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            )
    }

    private var aiFeatureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI 文生图")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)

            Text("输入您的创意想法，AI 将为您生成专业苏绣设计图")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.black.opacity(0.55))
                .lineLimit(2)

            Button(action: onAICardTap) {
                HStack(spacing: 6) {
                    Text("立即体验")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 20).fill(accentGreen))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - ProfileView
struct ProfileView: View {
    private let works = ["Work1", "Work2", "Work3", "Work4"]
    private let bgColor = Color(red: 0.93, green: 0.95, blue: 0.97)
    private let accentBlue = Color(red: 0.2, green: 0.48, blue: 0.95)

    var body: some View {
        profileContent
    }

    private var profileContent: some View {
        ZStack(alignment: .topLeading) {
            bgColor.ignoresSafeArea(edges: .top)

            // 装饰图 - 使用 SF Symbols 占位
            Image(systemName: "flower.petals")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .offset(x: -150, y: -150)
                .opacity(0.8)
                .foregroundColor(.black.opacity(0.1))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    profileHeader
                    statsRow.padding(.top, 22)
                    worksSection.padding(.top, 26)
                    menuSection.padding(.top, 20)
                    Spacer(minLength: 100)
                }
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                Image("ProfileAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
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
            .aspectRatio(contentMode: .fill)
            .frame(width: 130, height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
    }

    private var menuSection: some View {
        VStack(spacing: 0) {
            menuRow(icon: "bag", title: "我的订单")
            menuRow(icon: "heart", title: "我的收藏")
            menuRow(icon: "clock", title: "历史记录")
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
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

// MARK: - MarketView
struct MarketView: View {
    @State private var selectedTab: Int = 0
    @State private var searchText: String = ""

    var onProfileTap: () -> Void

    private let bgColor = Color(red: 0.97, green: 0.97, blue: 0.98)
    private let suxiuBlue = Color(hex: "004FB8")

    private let products = [
        Product(id: 1, name: "牡丹苏绣成品挂画", tags: ["苏绣", "刺绣", "挂画"], price: 360, image: "MarketProduct1"),
        Product(id: 2, name: "凤凰苏绣挂画", tags: ["苏绣", "刺绣", "凤凰"], price: 660, image: "MarketProduct2"),
        Product(id: 3, name: "荷花苏绣摆件", tags: ["苏绣", "刺绣", "荷花"], price: 480, image: "MarketProduct3"),
        Product(id: 4, name: "山水苏绣屏风", tags: ["苏绣", "刺绣", "山水"], price: 1280, image: "MarketProduct1"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea(edges: .top)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        categorySegmentedControl
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        searchBar
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        filterButtons
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        productGrid
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        Spacer(minLength: 100)
                    }
                }
            }
            #if os(iOS)
            .navigationTitle("SuMarket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onProfileTap) {
                        Image("ProfileAvatar")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    }
                }
            }
            #endif
        }
    }

    private var categorySegmentedControl: some View {
        HStack(spacing: 0) {
            Button(action: { selectedTab = 0 }) {
                Text("成品")
                    .font(.system(size: 16, weight: selectedTab == 0 ? .semibold : .medium))
                    .foregroundColor(selectedTab == 0 ? suxiuBlue : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == 0 ? Color.white : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedTab == 0 ? suxiuBlue : Color.clear, lineWidth: 2)
                    )
            }

            Button(action: { selectedTab = 1 }) {
                Text("自定义")
                    .font(.system(size: 16, weight: selectedTab == 1 ? .semibold : .medium))
                    .foregroundColor(selectedTab == 1 ? suxiuBlue : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == 1 ? Color.white : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedTab == 1 ? suxiuBlue : Color.clear, lineWidth: 2)
                    )
            }
        }
        .padding(.horizontal, 4)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.gray.opacity(0.6))

            TextField("搜索苏绣纹样，主题或品类...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.black)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(text: "所有", isSelected: true)
                FilterChip(text: "Random Stitch", isSelected: false)
                FilterChip(text: "Fine Art", isSelected: false)
                FilterChip(text: "Modern", isSelected: false)
                FilterChip(text: "Traditional", isSelected: false)
            }
            .padding(.horizontal, 4)
        }
    }

    private var productGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(products) { product in
                ProductCard(product: product)
            }
        }
    }
}

struct FilterChip: View {
    let text: String
    let isSelected: Bool

    private let suxiuBlue = Color(hex: "004FB8")

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? suxiuBlue : Color.white)
            )
            .overlay(
                Capsule()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? suxiuBlue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
    }
}

struct ProductCard: View {
    let product: Product

    @State private var isLiked: Bool = false

    private let suxiuBlue = Color(hex: "004FB8")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(product.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 150, maxHeight: 250)
                    .clipped()
                    #if os(iOS)
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                    #else
                    .cornerRadius(16)
                    #endif

                Button(action: { isLiked.toggle() }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isLiked ? .red : .white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.8))
                        )
                }
                .padding(.trailing, 10)
                .padding(.top, 10)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    ForEach(product.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10))
                            .foregroundColor(suxiuBlue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(suxiuBlue.opacity(0.1))
                            )
                    }
                }

                HStack {
                    Text("¥\(product.price)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(suxiuBlue)

                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
        }
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

#if os(iOS)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
#endif

struct Product: Identifiable {
    let id: Int
    let name: String
    let tags: [String]
    let price: Int
    let image: String
}

// MARK: - RecommendView
struct RecommendView: View {
    @State private var selectedTab: Int = 0
    @State private var searchText: String = ""

    private let bgColor = Color(red: 0.97, green: 0.97, blue: 0.98)
    private let suxiuBlue = Color(hex: "004FB8")
    private let accentGreen = Color(hex: "00BFA5")

    private let categories = ["首页", "定制", "发现", "艺术家"]
    private let topics = ["苏绣专题", "苏绣技法", "工坊故事", "苏绣故事", "针法教程"]

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea(edges: .top)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    headerSection
                        .padding(.horizontal, 20)

                    categoryTabs
                        .padding(.horizontal, 20)

                    bannerSection
                        .padding(.horizontal, 20)

                    topicChips
                        .padding(.horizontal, 20)

                    contentCards
                        .padding(.horizontal, 20)

                    bannerCard3
                        .padding(.horizontal, 20)

                    Spacer(minLength: 80)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            // 搜索框
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(.gray.opacity(0.5))
                    .frame(width: 20)

                TextField("搜索苏绣纹样，主题或品类...", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )

            // 用户和收藏按钮
            HStack {
                Spacer()

                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.gray)
                .padding(.leading, 12)

                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                .padding(.leading, 8)
            }
        }
    }

    private var categoryTabs: some View {
        HStack(spacing: 20) {
            ForEach(0..<categories.count, id: \.self) { index in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: 4) {
                        Text(categories[index])
                            .font(.system(size: 15, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundColor(selectedTab == index ? suxiuBlue : .black)

                        if selectedTab == index {
                            Rectangle()
                                .fill(suxiuBlue)
                                .frame(width: 20, height: 2.5)
                                .cornerRadius(1)
                        }
                    }
                }
            }
        }
    }

    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                #if os(iOS)
                if UIImage(named: "RecommendBanner1") != nil {
                    Image("RecommendBanner1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 150, maxHeight: 250)
                        .cornerRadius(16)
                        .clipped()
                } else {
                    bannerPlaceholder
                }
                #else
                bannerPlaceholder
                #endif

                VStack(alignment: .leading, spacing: 8) {
                    Text("苏绣专题")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentGreen)
                        )

                    Text("THE PEONY SCROLL : ETERNAL SPRING")
                        .font(.custom("Times New Roman", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(16)
            }
        }
    }

    private var bannerPlaceholder: some View {
        LinearGradient(
            colors: [suxiuBlue.opacity(0.6), suxiuBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 200)
        .cornerRadius(16)
        .overlay(
            Image(systemName: "flower.petals")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.2))
                .rotationEffect(.degrees(15))
        )
        .clipped()
    }

    private var topicChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<topics.count, id: \.self) { index in
                    TopicChip(text: topics[index], isSelected: index == 0)
                }
            }
        }
    }

    private var contentCards: some View {
        HStack(spacing: 16) {
            ContentCard(
                image: "RecommendCard1",
                title: "苏绣非遗传承人孟奶奶",
                subtitle: "创作者故事：孟奶奶四十载坚守绣坊，以针为笔复刻江南盛景，将岁月晕染在绫罗绸缎之上。",
                tag: "创作者故事"
            )

            ContentCard(
                image: "RecommendCard2",
                title: "苏绣传承专用桑蚕丝线",
                subtitle: "故事：它们自江南桑林而来，在绣娘手中化作花鸟虫鱼，每一根丝都承载着千年技艺的传承。",
                tag: "材料故事"
            )
        }
    }

    private var bannerCard3: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 使用渐变背景替代缺失的图片资源
            LinearGradient(
                colors: [suxiuBlue.opacity(0.4), suxiuBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 160)
            .cornerRadius(16)
            .overlay(
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.15))
            )
            .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text("苏绣工坊")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(suxiuBlue)
                    )

                Text("传统织机展示")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                Text("探索古老的苏绣织造工艺，见证传统技艺的魅力")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(suxiuBlue)
            )
            .padding(.top, -1)
        }
    }
}

struct TopicChip: View {
    let text: String
    let isSelected: Bool

    private let suxiuBlue = Color(hex: "004FB8")
    private let accentGreen = Color(hex: "00BFA5")

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? accentGreen : Color.white)
            )
            .overlay(
                Capsule()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? accentGreen.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
    }
}

struct ContentCard: View {
    let image: String?
    let title: String
    let subtitle: String
    let tag: String

    @State private var isLiked: Bool = false

    private let suxiuBlue = Color(hex: "004FB8")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if let imageName = image {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 150, maxHeight: 200)
                        .clipped()
                        #if os(iOS)
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                        #else
                        .cornerRadius(16)
                        #endif
                } else {
                    // 使用渐变背景替代缺失的图片
                    LinearGradient(
                        colors: [suxiuBlue.opacity(0.5), suxiuBlue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                    )
                    .clipped()
                    #if os(iOS)
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                    #else
                    .cornerRadius(16)
                    #endif
                }

                Button(action: { isLiked.toggle() }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isLiked ? .red : .white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.9))
                        )
                }
                .padding(.trailing, 10)
                .padding(.top, 10)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
        }
        .shadow(color: .black.opacity(0.1), radius: 14, x: 0, y: 5)
    }
}

// MARK: - HomeView (Main)
struct HomeView: View {
    @State private var selectedTab: Int = 0
    @State private var navigateToAIGenerate = false
    @State private var navigateToProfile = false
    @Namespace private var tabSelectionNamespace

    private let bgColor = Color(red: 0.93, green: 0.95, blue: 0.97)
    private let accentBlue = Color(red: 0.2, green: 0.48, blue: 0.95)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                bgColor.ignoresSafeArea(edges: .top)

                GeometryReader { proxy in
                    contentBody
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.height,
                            alignment: .topLeading
                        )
                        .clipped()
                }

                liquidTabBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 2)
                    .offset(y: 10)
            }
            #if os(iOS)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image("SuxiuBrandMarkV2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .accessibilityHidden(true)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { navigateToProfile = true }) {
                        Image("ProfileAvatar")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToAIGenerate) {
                AIGenerateView()
            }
            .navigationDestination(isPresented: $navigateToProfile) {
                ProfileView()
            }
            #endif
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        switch selectedTab {
        case 0:
            HeritageHomeView(onAICreate: { navigateToAIGenerate = true })
        case 1:
            LearningCenterView()
        case 2:
            CommunityHubView()
        case 3:
            MarketplaceHubView()
        default:
            HeritageHomeView(onAICreate: { navigateToAIGenerate = true })
        }
    }

    private var navigationTitle: String {
        switch selectedTab {
        case 0: return "苏绣数字博物馆"
        case 1: return "苏绣学习馆"
        case 2: return "绣友社区"
        case 3: return "苏绣市集"
        default: return "锦绣 AI"
        }
    }

    private var liquidTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "building.columns", selectedIcon: "building.columns.fill", label: "文化", tag: 0)
            tabItem(icon: "graduationcap", selectedIcon: "graduationcap.fill", label: "学习", tag: 1)
            magicButton
            tabItem(icon: "bubble.left.and.bubble.right", selectedIcon: "bubble.left.and.bubble.right.fill", label: "社区", tag: 2)
            tabItem(icon: "handbag", selectedIcon: "handbag.fill", label: "市集", tag: 3)
        }
        .frame(height: 54)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .suxiuFloatingGlass(in: Capsule())
    }

    private var magicButton: some View {
        Button(action: { navigateToAIGenerate = true }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.001))
                    .frame(width: 46, height: 46)
                    .suxiuTintedGlass(in: Circle())
                    .shadow(color: accentBlue.opacity(0.30), radius: 12, x: 0, y: 6)

                Image(systemName: "scribble.variable")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("打开 AI 创作工坊")
    }

    private func tabItem(icon: String, selectedIcon: String, label: String, tag: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.25)) { selectedTab = tag }
        }) {
            VStack(spacing: 3) {
                Image(systemName: selectedTab == tag ? selectedIcon : icon)
                    .font(.system(size: 18, weight: selectedTab == tag ? .semibold : .regular))
                    .foregroundColor(selectedTab == tag ? accentBlue : .black.opacity(0.5))
                    .scaleEffect(selectedTab == tag ? 1.08 : 1.0)

                Text(label)
                    .font(.system(size: 10, weight: selectedTab == tag ? .semibold : .medium))
                    .foregroundColor(selectedTab == tag ? accentBlue : .black.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background {
                if selectedTab == tag {
                    Capsule()
                        .fill(Color.white.opacity(0.42))
                        .matchedGeometryEffect(id: "tab-selection", in: tabSelectionNamespace)
                }
            }
        }
        .animation(.spring(response: 0.25), value: selectedTab)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selectedTab == tag ? .isSelected : [])
    }
}

#Preview { HomeView() }
