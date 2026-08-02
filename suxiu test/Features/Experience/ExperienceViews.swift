import SwiftUI
#if os(iOS)
import SafariServices
#endif

#if os(iOS)
struct SuxiuLessonBrowser: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true
        return SFSafariViewController(url: url, configuration: configuration)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif

// MARK: - Shared competition design language

private extension Color {
    static let heritageInk = Color(red: 0.07, green: 0.11, blue: 0.16)
    static let heritageBlue = Color(red: 0.0, green: 0.31, blue: 0.72)
    static let heritageJade = Color(red: 0.0, green: 0.58, blue: 0.48)
    static let heritagePaper = Color(red: 0.965, green: 0.973, blue: 0.982)
    static let heritageMist = Color(red: 0.91, green: 0.94, blue: 0.97)
}

struct CompetitionPageBackground: View {
    var body: some View {
        ZStack {
            Color.heritagePaper
            RadialGradient(
                colors: [Color.heritageBlue.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 360
            )
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

/// 让横向素材始终按当前容器宽度裁切，避免图片原始宽高比撑大纵向页面。
struct SuxiuAspectFillImage: View {
    let name: String
    let height: CGFloat
    var cornerRadius: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct SuxiuSectionHeader: View {
    let eyebrow: String
    let title: String
    var actionTitle: String? = nil
    var action: () -> Void = {}

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(Color.heritageBlue)
                Text(title)
                    .font(.system(size: 23, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(Color.heritageInk)
            }
            Spacer()
            if let actionTitle {
                Button(action: action) {
                    HStack(spacing: 3) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.heritageBlue)
                }
            }
        }
    }
}

struct SuxiuTag: View {
    let text: String
    var tint: Color = .heritageBlue

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
    }
}

/// 统一的小尺寸图标容器：只使用苏绣蓝与纸白，避免分类卡片出现杂乱的彩色徽章。
struct SuxiuIconBadge: View {
    let systemName: String
    var size: CGFloat = 44
    var symbolSize: CGFloat = 20

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
                .fill(Color.heritageBlue.opacity(0.09))
            RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
                .stroke(Color.heritageBlue.opacity(0.16), lineWidth: 0.8)
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(Color.heritageBlue)
        }
        .frame(width: size, height: size)
    }
}

struct DemoNotice: View {
    var text: String = "比赛演示数据 · 内容来源将在正式版本中逐条标注"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal")
            Text(text)
            Spacer(minLength: 0)
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(12)
        .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 文化首页 / 每日苏绣博物馆

struct HeritageHomeView: View {
    var onAICreate: () -> Void

    @State private var selectedTopic: HeritageTopic?
    @State private var showRestoration = false

    private let topics = HeritageTopic.samples

    var body: some View {
        ZStack {
            CompetitionPageBackground()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 28) {
                    museumHero
                    topicGrid
                    dailyArchive
                    restorationFeature
                    provenanceNote
                    Spacer(minLength: 112)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .containerRelativeFrame(.horizontal, alignment: .leading)
            }
        }
        .sheet(item: $selectedTopic) { topic in
            HeritageTopicDetail(topic: topic)
        }
        .sheet(isPresented: $showRestoration) {
            RestorationDemoView()
        }
    }

    private var museumHero: some View {
        ZStack(alignment: .bottomLeading) {
            SuxiuAspectFillImage(name: "OpenSuxiuProcess", height: 310)

            LinearGradient(
                colors: [.clear, Color.heritageInk.opacity(0.88)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("DAILY COLLECTION · 001")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.72))
                Text("一根丝线里的江南")
                    .font(.system(size: 29, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                Text("从劈丝、配色到针脚方向，放大观看苏绣如何用丝线表现花瓣的明暗与质感。")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineSpacing(3)
                Button(action: { selectedTopic = topics[0] }) {
                    Label("查看今日藏品", systemImage: "viewfinder")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.heritageBlue.opacity(0.15), radius: 22, x: 0, y: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("每日一绣，一根丝线里的江南")
    }

    private var topicGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            SuxiuSectionHeader(eyebrow: "EXPLORE", title: "六条文化线索")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(topics) { topic in
                    Button(action: { selectedTopic = topic }) {
                        VStack(alignment: .leading, spacing: 12) {
                            SuxiuIconBadge(systemName: topic.icon)

                            Text(topic.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.heritageInk)
                            Text(topic.subtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text("收录 \(topic.count) 项")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.heritageBlue)
                        }
                        .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
                        .padding(16)
                        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dailyArchive: some View {
        VStack(alignment: .leading, spacing: 16) {
            SuxiuSectionHeader(eyebrow: "DIGITAL ARCHIVE", title: "数字档案", actionTitle: "档案索引")
            HStack(spacing: 14) {
                archiveStat(value: "6", label: "内容门类")
                archiveStat(value: "128", label: "演示条目")
                archiveStat(value: "24", label: "高清局部")
            }
            .padding(18)
            .background(Color.heritageInk, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private func archiveStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var restorationFeature: some View {
        Button(action: { showRestoration = true }) {
            HStack(spacing: 16) {
                SuxiuIconBadge(systemName: "viewfinder", size: 70, symbolSize: 27)
                    .frame(height: 82)

                VStack(alignment: .leading, spacing: 7) {
                    SuxiuTag(text: "AI 数字保护", tint: .heritageJade)
                    Text("老绣片修复实验室")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.heritageInk)
                    Text("区分原始图像、AI 推测区域与人工确认记录。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.heritageJade)
            }
            .padding(16)
            .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var provenanceNote: some View {
        DemoNotice(text: "开放图片已记录来源与许可；档案内容采用“来源—版权—审核状态”三项标记。")
    }
}

struct HeritageTopic: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let image: String
    let count: Int
    let tint: Color
    let overview: [String]
    let articles: [HeritageArticle]
    let resources: [HeritageResource]

    static let samples: [HeritageTopic] = [
        .init(
            title: "每日一绣",
            subtitle: "经典作品与局部细读",
            icon: "photo.artframe",
            image: "OpenSuxiuProcess",
            count: 24,
            tint: .heritageBlue,
            overview: [
                "苏绣并不只追求“像”，它通过丝线粗细、针脚方向和色阶过渡，让同一块绣面在不同观看角度呈现细微光泽。近看是针脚秩序，退后则形成完整画面。",
                "国家级非遗资料记载，宋代以来的实物呈现了技艺演变：元代残片已综合运用多种针法，明代更多借鉴文人画稿，清代商品绣兴盛，苏州形成被称作“绣市”的行业景观。"
            ],
            articles: [
                .init(title: "从一根丝线开始看作品", summary: "辨认丝线的走向、反光和叠压关系，理解绣娘如何用线代替画笔。", readingTime: "5 分钟"),
                .init(title: "顾绣与画绣传统", summary: "从画稿、设色到落针，观察刺绣如何吸收中国绘画的构图与笔墨趣味。", readingTime: "7 分钟"),
                .init(title: "苏绣猫的丝毛表现", summary: "以施针、套针和细密色阶模拟毛发转折，重点观察眼神、胡须与明暗边界。", readingTime: "6 分钟"),
                .init(title: "为什么要换角度看绣面", summary: "丝线具有方向性反光；同一色线因针脚角度不同，会产生近似深浅变化。", readingTime: "4 分钟")
            ],
            resources: [
                .init(title: "国家级非遗代表性项目：苏绣", provider: "中国非物质文化遗产网", kind: .article, url: "https://www.ihchina.cn/project_details/13978/"),
                .init(title: "《指尖上的传承》第二集：苏绣", provider: "CCTV 纪录", kind: .video, url: "https://www.youtube.com/watch?v=i9ZXblWeGeA")
            ]
        ),
        .init(
            title: "纹样百科",
            subtitle: "花鸟、瑞兽与江南意象",
            icon: "camera.macro",
            image: "OpenSuxiuBogu",
            count: 36,
            tint: .heritageBlue,
            overview: [
                "苏绣纹样既是画面，也是可以被阅读的视觉语言。花卉、禽鸟、器物与瑞兽常通过谐音、典故和组合关系表达祝愿。",
                "理解纹样时，需要同时观察主体、陪衬、季节和使用场景。相同的牡丹或凤凰，在服饰、屏风与礼赠绣品中可能承担不同的叙事功能。"
            ],
            articles: [
                .init(title: "牡丹：富贵之外", summary: "比较独枝、折枝和团花构图，理解牡丹与禽鸟、瓶器组合后的意义变化。", readingTime: "6 分钟"),
                .init(title: "博古图中的清供世界", summary: "瓶、炉、书卷与花枝共同构成文人清供，器物次序往往比单个符号更重要。", readingTime: "8 分钟"),
                .init(title: "凤凰与百鸟的秩序", summary: "从尾羽、云纹和花枝的方向观察画面如何建立中心、对称与仪式感。", readingTime: "6 分钟"),
                .init(title: "江南花鸟的留白", summary: "留白并非“没有绣”，而是为丝线光泽、主体呼吸感和观看距离预留空间。", readingTime: "5 分钟")
            ],
            resources: [
                .init(title: "中国刺绣开放馆藏分类", provider: "Wikimedia Commons", kind: .archive, url: "https://commons.wikimedia.org/wiki/Category:Chinese_embroidery"),
                .init(title: "苏绣博古图镜片（清）", provider: "上海博物馆藏 / Wikimedia Commons", kind: .archive, url: "https://commons.wikimedia.org/wiki/File:%E8%8B%8F%E7%BB%A3%E5%8D%9A%E5%8F%A4%E5%9B%BE%E9%95%9C%E7%89%87.jpg")
            ]
        ),
        .init(
            title: "针法图鉴",
            subtitle: "从平绣到乱针绣",
            icon: "scribble.variable",
            image: "OpenSuxiuCat",
            count: 18,
            tint: .heritageBlue,
            overview: [
                "针法不是孤立的名称，而是处理轮廓、体积、质感和色层的方法。方向稳定的平针适合铺陈，长短交错的施针适合丝毛，交叉叠色的乱针则善于塑造光影。",
                "当代传承人在传统针法基础上持续创新。真正的学习重点不是记住名词，而是判断对象需要怎样的线迹方向、密度和层次。"
            ],
            articles: [
                .init(title: "平针：整齐并不等于僵硬", summary: "控制针脚平行关系，同时让方向顺应花瓣、叶片或衣纹的结构。", readingTime: "5 分钟"),
                .init(title: "套针：用层层衔接完成渐变", summary: "后排针脚嵌入前排，减少明显接缝，适合花瓣和羽毛的连续色阶。", readingTime: "7 分钟"),
                .init(title: "施针：表现毛发与细枝", summary: "通过长短不齐和方向变化减弱边界，让猫毛、鸟羽与枝叶更自然。", readingTime: "6 分钟"),
                .init(title: "乱针绣：交错线迹中的光影", summary: "以多方向、多色层的线迹塑造体积，阅读时可先找主方向，再看叠色。", readingTime: "8 分钟")
            ],
            resources: [
                .init(title: "一针一线传绝技：苏绣传承一瞥", provider: "光明日报", kind: .article, url: "https://news.gmw.cn/2024-08/14/content_37498112.htm"),
                .init(title: "针尖乾坤，丝像万千", provider: "央视网", kind: .video, url: "https://tv.cctv.com/v/a/ARTIVIpiNqLjdOGvS5VByftZ181227.html")
            ]
        ),
        .init(
            title: "材料知识",
            subtitle: "丝线、绷架与绣底",
            icon: "circle.hexagongrid.fill",
            image: "OpenSuxiuLingxian",
            count: 16,
            tint: .heritageBlue,
            overview: [
                "丝线、绣底和绷架共同决定针脚能否稳定呈现。丝线有天然光泽，劈成更细线束后可以获得更柔和的过渡，但也更考验手的力度。",
                "绣底既要承受反复穿刺，又不能遮蔽丝线细节。上绷时张力应均匀；过松容易起皱，过紧则可能造成变形。"
            ],
            articles: [
                .init(title: "桑蚕丝为什么会发光", summary: "观察丝纤维表面对光线的反射，理解方向与色彩为何必须一起设计。", readingTime: "5 分钟"),
                .init(title: "劈丝：把一根线分成更细层级", summary: "线径越细，渐变越柔和；同时也需要更稳定的张力与更长制作时间。", readingTime: "6 分钟"),
                .init(title: "绷架与张力", summary: "通过均匀固定绣底保持平整，并在制作过程中持续检查松紧变化。", readingTime: "4 分钟"),
                .init(title: "绫、缎与不同绣底", summary: "比较表面纹理、密度与反光，理解材料如何影响构图和观看效果。", readingTime: "6 分钟")
            ],
            resources: [
                .init(title: "苏绣项目知识与历史", provider: "中国非物质文化遗产网", kind: .article, url: "https://www.ihchina.cn/project_details/13978/"),
                .init(title: "中国丝绣局部开放图像", provider: "Wikimedia Commons", kind: .archive, url: "https://commons.wikimedia.org/wiki/File:Detail_of_Chinese_silk_embroidery.jpg")
            ]
        ),
        .init(
            title: "匠人故事",
            subtitle: "口述、工坊与传承路径",
            icon: "person.crop.square",
            image: "OpenSuxiuWorkshop",
            count: 14,
            tint: .heritageBlue,
            overview: [
                "一件绣品通常经过选题、画稿、配色、上绷、刺绣、整理等多个环节。匠人的经验不仅存在于成品中，也保存在口述、手势、返工痕迹和工坊协作里。",
                "今天的传承同时面对教学、设计转译和市场变化。记录匠人如何判断材料、修改画稿和解决失误，比只展示最终成品更接近真实技艺。"
            ],
            articles: [
                .init(title: "从画稿到绣稿", summary: "画面进入绣制前，需要调整线条密度、色层数量和可操作的针脚方向。", readingTime: "7 分钟"),
                .init(title: "工坊中的协作", summary: "大型作品可能由多人分工，统一色卡、针法尺度和交接标准尤为重要。", readingTime: "6 分钟"),
                .init(title: "传承人的口述档案", summary: "记录判断过程、失败经验与学习路径，让难以文字化的手艺获得上下文。", readingTime: "8 分钟"),
                .init(title: "年轻创作者如何转译传统", summary: "在尊重工艺逻辑的前提下调整题材、尺寸与使用场景，而非只更换表面图案。", readingTime: "6 分钟")
            ],
            resources: [
                .init(title: "一针一线传绝技：当代传承与创新", provider: "光明日报", kind: .article, url: "https://news.gmw.cn/2024-08/14/content_37498112.htm"),
                .init(title: "与姚建萍老师共度苏绣时光", provider: "苏州博物馆", kind: .video, url: "https://www.szmuseum.com/News/Details/a144de70-702f-45f6-b2f5-fa81f1240b50")
            ]
        ),
        .init(
            title: "数字档案",
            subtitle: "年代、出处与授权记录",
            icon: "archivebox.fill",
            image: "OpenSuxiuCourtRobe",
            count: 20,
            tint: .heritageBlue,
            overview: [
                "数字档案不只是保存一张图片，还应记录作品名称、年代、尺寸、材质、馆藏、拍摄者、许可和审核状态。缺少出处的高清图仍然不是完整档案。",
                "对于 AI 修复或推测内容，应保留原图、处理版本、修改区域和人工审核记录，使观看者能够区分历史证据与技术补全。"
            ],
            articles: [
                .init(title: "一张图片需要哪些元数据", summary: "从作品信息到拍摄与授权信息，建立可核查、可持续更新的记录。", readingTime: "5 分钟"),
                .init(title: "高清局部如何标注", summary: "标明局部在原作中的位置、倍率和观察目的，避免脱离整体误读。", readingTime: "4 分钟"),
                .init(title: "开放许可并不等于没有条件", summary: "区分公共领域、署名许可和相同方式共享，使用时保留作者与原页面。", readingTime: "6 分钟"),
                .init(title: "AI 修复的版本记录", summary: "把推测区域与原始证据分层保存，并记录工具、日期和审核结论。", readingTime: "7 分钟")
            ],
            resources: [
                .init(title: "苏州博物馆馆藏与研究入口", provider: "苏州博物馆", kind: .archive, url: "https://www.szmuseum.com/"),
                .init(title: "苏州博物馆开放馆藏分类", provider: "Wikimedia Commons", kind: .archive, url: "https://commons.wikimedia.org/wiki/Category:Collections_of_the_Suzhou_Museum"),
                .init(title: "雍正时期苏州织造刺绣龙袍", provider: "Peabody Essex Museum / Wikimedia Commons", kind: .archive, url: "https://commons.wikimedia.org/wiki/File:Court_robe_with_dragons_and_clouds,_China,_embroidery_by_Imperial_Silk_Manufactory,_Suzhou,_tailoring_by_Imperial_Workshop,_Beijing,_Yongzheng_period,_1723-1735_AD,_silk_-_Peabody_Essex_Museum_-_DSC07916.jpg")
            ]
        )
    ]
}

struct HeritageArticle: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let readingTime: String
}

struct HeritageResource: Identifiable {
    enum Kind {
        case article
        case video
        case archive

        var label: String {
            switch self {
            case .article: return "图文"
            case .video: return "视频"
            case .archive: return "馆藏"
            }
        }

        var icon: String {
            switch self {
            case .article: return "doc.text"
            case .video: return "play.rectangle"
            case .archive: return "archivebox"
            }
        }
    }

    let id = UUID()
    let title: String
    let provider: String
    let kind: Kind
    let url: URL

    init(title: String, provider: String, kind: Kind, url: String) {
        self.title = title
        self.provider = provider
        self.kind = kind
        self.url = URL(string: url)!
    }
}

struct HeritageTopicDetail: View {
    let topic: HeritageTopic
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CompetitionPageBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SuxiuAspectFillImage(name: topic.image, height: 210, cornerRadius: 24)
                            .overlay(alignment: .topTrailing) {
                                SuxiuTag(text: "开放图片", tint: topic.tint)
                                    .padding(12)
                            }

                        Text(topic.title)
                            .font(.system(size: 30, weight: .bold))
                        Text(topic.subtitle)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("线索导读")
                                .font(.system(size: 19, weight: .bold))
                            ForEach(topic.overview, id: \.self) { paragraph in
                                Text(paragraph)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.heritageInk.opacity(0.82))
                                    .lineSpacing(5)
                            }
                        }
                        .padding(18)
                        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18))

                        SuxiuSectionHeader(eyebrow: "READING", title: "专题阅读")

                        ForEach(Array(topic.articles.enumerated()), id: \.element.id) { index, article in
                            VStack(alignment: .leading, spacing: 9) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(String(format: "%02d", index + 1))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(topic.tint)
                                    Text(article.title)
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    Text(article.readingTime)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                Text(article.summary)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding(16)
                            .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 16))
                        }

                        SuxiuSectionHeader(eyebrow: "SOURCES", title: "延伸资料")

                        ForEach(topic.resources) { resource in
                            Link(destination: resource.url) {
                                HStack(spacing: 13) {
                                    SuxiuIconBadge(systemName: resource.kind.icon, size: 42, symbolSize: 18)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(resource.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.heritageInk)
                                            .multilineTextAlignment(.leading)
                                        Text("\(resource.kind.label) · \(resource.provider)")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(topic.tint)
                                }
                                .padding(14)
                                .background(topic.tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 15))
                            }
                        }

                        DemoNotice(text: "外部资料将打开原始页面；图片、视频和文字版权归各来源方所有。")
                    }
                    .padding(20)
                }
            }
            .navigationTitle("文化档案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
        }
    }
}

// MARK: - AI 数字修复

struct RestorationDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var restored = false
    @State private var selectedMethod = 0

    var body: some View {
        NavigationStack {
            ZStack {
                CompetitionPageBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AI RESTORATION LAB")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.6)
                                .foregroundStyle(Color.heritageJade)
                            Text("老绣片数字修复")
                                .font(.system(size: 29, weight: .bold))
                            Text("所有补全区域均为 AI 推测，不替代文物修复结论。")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        ZStack(alignment: .topLeading) {
                            SuxiuAspectFillImage(name: "OpenSuxiuBogu", height: 330)
                                .saturation(restored ? 1.0 : 0.32)
                                .contrast(restored ? 1.03 : 0.82)
                                .overlay(Color.brown.opacity(restored ? 0.0 : 0.22))
                            SuxiuTag(text: restored ? "AI 推测预览" : "原始影像", tint: restored ? .heritageJade : .orange)
                                .padding(14)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .animation(.easeInOut(duration: 0.45), value: restored)

                        Picker("修复策略", selection: $selectedMethod) {
                            Text("保守补色").tag(0)
                            Text("纹样补全").tag(1)
                            Text("结构增强").tag(2)
                        }
                        .pickerStyle(.segmented)

                        Button(action: { restored.toggle() }) {
                            Label(restored ? "查看原始影像" : "生成修复预览", systemImage: restored ? "arrow.uturn.backward" : "wand.and.stars")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.heritageJade, in: RoundedRectangle(cornerRadius: 14))
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("修复记录").font(.system(size: 18, weight: .bold))
                            restorationRow(icon: "photo", title: "原始图像", value: "已保留")
                            restorationRow(icon: "square.dashed", title: "AI 推测区域", value: "3 处")
                            restorationRow(icon: "person.crop.circle.badge.checkmark", title: "人工复核", value: "待确认")
                        }
                        .padding(18)
                        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
        }
    }

    private func restorationRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(Color.heritageJade).frame(width: 24)
            Text(title).font(.system(size: 14, weight: .medium))
            Spacer()
            Text(value).font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
}

// MARK: - 苏绣学习馆

struct LearningCenterView: View {
    @State private var selectedCourse: LearningCourse?
    @State private var completedLessons = 2

    private let courses = LearningCourse.samples

    var body: some View {
        ZStack {
            CompetitionPageBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    learningHero
                    weeklyPractice
                    courseList
                    aiCoach
                    DemoNotice(text: "课程步骤为比赛教学演示；公开视频均保留原作者、原平台与原页面。")
                    Spacer(minLength: 112)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .containerRelativeFrame(.horizontal, alignment: .leading)
            }
        }
        .sheet(item: $selectedCourse) { course in
            CourseDetailView(course: course, completedLessons: $completedLessons)
        }
    }

    private var learningHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LEARNING STUDIO")
                        .font(.system(size: 11, weight: .bold)).tracking(1.7)
                        .foregroundStyle(Color.heritageBlue)
                    Text("今天，从一针开始")
                        .font(.system(size: 28, weight: .bold))
                    Text("连续学习 3 天 · 本周 18 分钟")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle().stroke(Color.heritageBlue.opacity(0.14), lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: 0.58)
                        .stroke(Color.heritageBlue, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("58%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .frame(width: 70, height: 70)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.80), in: RoundedRectangle(cornerRadius: 22))
    }

    private var weeklyPractice: some View {
        Button(action: { selectedCourse = courses[1] }) {
            HStack(spacing: 16) {
                Image("Materials")
                    .resizable().scaledToFill()
                    .frame(width: 92, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 7) {
                    SuxiuTag(text: "本周练习", tint: .orange)
                    Text("用平针表现一片花瓣")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.heritageInk)
                    Text("练习线迹方向与疏密变化，预计 15 分钟。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                    Label("继续练习", systemImage: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.heritageBlue)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var courseList: some View {
        VStack(alignment: .leading, spacing: 16) {
            SuxiuSectionHeader(eyebrow: "5-MINUTE LESSONS", title: "针法微课")
            ForEach(courses) { course in
                Button(action: { selectedCourse = course }) {
                    HStack(spacing: 14) {
                        SuxiuIconBadge(systemName: course.icon, size: 54, symbolSize: 22)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.heritageInk)
                            Text("\(course.duration) · \(course.level)").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill").font(.system(size: 25)).foregroundStyle(Color.heritageBlue)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 17))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var aiCoach: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SuxiuIconBadge(systemName: "viewfinder", size: 42, symbolSize: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI 针脚陪练").font(.system(size: 17, weight: .bold))
                    Text("拍照分析线迹密度、方向与配色").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                SuxiuTag(text: "线迹方向", tint: .heritageJade)
                SuxiuTag(text: "疏密变化", tint: .heritageJade)
                SuxiuTag(text: "配色建议", tint: .heritageJade)
            }
        }
        .padding(18)
        .background(Color.heritageJade.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct LearningCourse: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let level: String
    let icon: String
    let tint: Color
    let summary: String
    let materials: [String]
    let steps: [LessonStep]
    let video: LessonVideo

    static let samples: [LearningCourse] = [
        .init(
            title: "认识苏绣与工具",
            duration: "5 分钟",
            level: "入门",
            icon: "seal",
            tint: .heritageBlue,
            summary: "从绣绷、绣底和丝线开始，完成穿针、起针与收针的第一次练习。",
            materials: ["绣绷", "素色绣布", "7 号绣针", "桑蚕丝线"],
            steps: [
                .init(title: "认识绷架与绣底", instruction: "将绣布经纬方向摆正，均匀拉紧后逐段锁紧绣绷。布面应平整，但不需要绷到失去弹性。", checkpoint: "轻敲布面时有均匀回弹，四周没有明显褶皱。"),
                .init(title: "选择绣针并劈丝", instruction: "先用单股或少股丝线练习。把丝线顺着原有捻向慢慢分开，穿针后保留合适线尾。", checkpoint: "丝线没有打结、起毛，针眼处线束保持平顺。"),
                .init(title: "练习起针与收针", instruction: "在练习区用短针脚固定线尾，再开始正式针脚；结束时将线尾藏入背面已有针脚中。", checkpoint: "正面看不到线结，背面线尾固定且不过分堆叠。")
            ],
            video: .init(
                title: "苏绣快速穿针窍门，起针和收针方法讲解",
                creator: "薛淑萍苏绣教学招生中",
                duration: "01:10",
                coverURL: "https://i2.hdslb.com/bfs/archive/b2dc7318983a2b43d9509c01777b6eec138de9db.jpg",
                pageURL: "https://www.bilibili.com/video/BV1qWQyYdECH/"
            )
        ),
        .init(
            title: "平针绣的方向控制",
            duration: "8 分钟",
            level: "入门",
            icon: "line.diagonal",
            tint: .heritageBlue,
            summary: "用平行针脚铺出一片花瓣，理解针脚方向如何影响丝线反光与画面明暗。",
            materials: ["练习绣布", "细绣针", "2 色丝线", "水消笔"],
            steps: [
                .init(title: "固定起针位置", instruction: "先画出花瓣外轮廓，从花瓣根部开始，沿轮廓边缘确定第一针的起落点。", checkpoint: "起针藏在轮廓内，第一针与花瓣生长方向一致。"),
                .init(title: "保持针距与方向", instruction: "后一针紧贴前一针平行落下，针脚长度随花瓣轮廓调整，不要让丝线互相挤压。", checkpoint: "从不同角度观看时，反光方向连续，没有突然跳变。"),
                .init(title: "调整疏密与收边", instruction: "靠近轮廓处缩短针脚，用相邻色少量穿插，补齐缝隙并柔化花瓣边缘。", checkpoint: "轮廓完整、布底不外露，背面没有过长跨线。")
            ],
            video: .init(
                title: "苏绣平针绣教程，可以通过这个教学练习双面绣",
                creator: "苏州传承人刺绣",
                duration: "03:55",
                coverURL: "https://i0.hdslb.com/bfs/archive/a0723c3a738457d4bc848e59b893cfa48b124d34.jpg",
                pageURL: "https://www.bilibili.com/video/BV15j411R71q/"
            )
        ),
        .init(
            title: "打籽绣的颗粒质感",
            duration: "7 分钟",
            level: "进阶",
            icon: "circle.grid.3x3.fill",
            tint: .heritageBlue,
            summary: "练习大小一致的结粒，再用疏密变化组合出花蕊的立体层次。",
            materials: ["绣绷", "细绣针", "丝线", "花蕊线稿"],
            steps: [
                .init(title: "确定结粒位置", instruction: "从标记点出针，让线贴近布面但保留自然张力，落针点与出针点保持很小间距。", checkpoint: "起落针位置清晰，丝线没有在布面扭转。"),
                .init(title: "绕针并形成结粒", instruction: "丝线绕针一至两圈，左手轻轻控制线圈，右手缓慢将针拉回绣底。", checkpoint: "线圈紧贴布面，结粒圆整且不会松脱。"),
                .init(title: "组合花蕊层次", instruction: "中心区域排列稍密，外围逐渐放松间距；保持绕线圈数一致以控制颗粒大小。", checkpoint: "结粒大小基本一致，疏密过渡自然，没有挤成一团。")
            ],
            video: .init(
                title: "打籽绣零基础教程",
                creator: "Trista大江",
                duration: "01:31",
                coverURL: "https://i2.hdslb.com/bfs/archive/536b05e63388358346ca204a191a22bc63d10eb6.jpg",
                pageURL: "https://www.bilibili.com/video/BV1Gv411C74j/"
            )
        ),
        .init(
            title: "乱针绣的色层",
            duration: "10 分钟",
            level: "进阶",
            icon: "scribble",
            tint: .heritageBlue,
            summary: "用交叉、长短不一的针线建立底色、中间色和亮部，体验乱针绣的叠色逻辑。",
            materials: ["绣绷", "细绣针", "3 色丝线", "明暗线稿"],
            steps: [
                .init(title: "建立底层色", instruction: "先用最长、最疏的针脚概括形体走势，针线朝多个方向交叉，但服从整体结构。", checkpoint: "底层保留布面呼吸感，主要明暗关系已经出现。"),
                .init(title: "交叉叠加中间色", instruction: "换相邻色，用不同长度的针脚穿插第一层，避免形成整齐的平行边界。", checkpoint: "两种颜色彼此渗透，看不到生硬的分区线。"),
                .init(title: "用短线调整边缘", instruction: "在转折、轮廓和亮部加入短针，局部加密；每完成一小块就退远检查整体。", checkpoint: "轮廓有虚实变化，亮部集中，画面没有被平均铺满。")
            ],
            video: .init(
                title: "苏绣基础针法课：程乱针绣的虚实与弯转",
                creator: "刺绣你辣么",
                duration: "00:48",
                coverURL: "https://i0.hdslb.com/bfs/archive/24a672662d1993249e64f5e4b80b9818ad52d348.jpg",
                pageURL: "https://www.bilibili.com/video/BV1vL4y1i7WA/"
            )
        )
    ]
}

struct LessonStep: Identifiable {
    let id = UUID()
    let title: String
    let instruction: String
    let checkpoint: String
}

struct LessonVideo {
    let title: String
    let creator: String
    let duration: String
    let coverURL: String
    let pageURL: String
}

struct CourseDetailView: View {
    let course: LearningCourse
    @Binding var completedLessons: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showVideo = false

    var body: some View {
        NavigationStack {
            ZStack {
                CompetitionPageBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        videoCard

                        VStack(alignment: .leading, spacing: 8) {
                            Text(course.title)
                                .font(.system(size: 27, weight: .bold))
                                .tracking(-0.5)
                            Text(course.summary)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }

                        materialsSection
                        stepSection
                        sourceNotice
                        Spacer(minLength: 92)
                    }
                    .padding(20)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: advance) {
                    Text(currentStep == course.steps.count - 1 ? "完成课程" : "下一步")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(course.tint, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("针法微课")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showVideo) {
                if let url = URL(string: course.video.pageURL) {
                    SuxiuLessonBrowser(url: url)
                        .ignoresSafeArea()
                }
            }
            #endif
        }
    }

    private var videoCard: some View {
        Button(action: { showVideo = true }) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: course.video.coverURL)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        ZStack {
                            Color.heritageBlue.opacity(0.10)
                            Image(systemName: course.icon)
                                .font(.system(size: 56, weight: .light))
                                .foregroundStyle(Color.heritageBlue)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipped()

                LinearGradient(
                    colors: [.clear, Color.heritageInk.opacity(0.86)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                HStack(alignment: .bottom, spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.heritageBlue)
                        .frame(width: 46, height: 46)
                        .background(.white, in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.video.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text("Bilibili · \(course.video.creator) · \(course.video.duration)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.70))
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
            }
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("播放公开视频：\(course.video.title)")
    }

    private var materialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("课前准备")
                .font(.system(size: 17, weight: .bold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(course.materials, id: \.self) { material in
                        Label(material, systemImage: "checkmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.heritageBlue)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(Color.heritageBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                    }
                }
            }
        }
    }

    private var stepSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("分步练习")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Text("\(currentStep + 1) / \(course.steps.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.heritageBlue)
            }

            ProgressView(value: Double(currentStep + 1), total: Double(course.steps.count))
                .tint(course.tint)

            HStack(spacing: 8) {
                ForEach(Array(course.steps.indices), id: \.self) { index in
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { currentStep = index } }) {
                        Text("第 \(index + 1) 步")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(index == currentStep ? .white : Color.heritageBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(index == currentStep ? Color.heritageBlue : Color.heritageBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(course.steps[currentStep].title)
                    .font(.system(size: 20, weight: .bold))
                Text(course.steps[currentStep].instruction)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineSpacing(5)

                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "scope")
                        .foregroundStyle(Color.heritageBlue)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("完成检查")
                            .font(.system(size: 12, weight: .semibold))
                        Text(course.steps[currentStep].checkpoint)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                }
                .padding(13)
                .background(Color.heritageBlue.opacity(0.07), in: RoundedRectangle(cornerRadius: 13))
            }
            .padding(17)
            .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var sourceNotice: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "link")
            Text("视频来自 Bilibili 公开原页面，版权归原作者所有；本项目仅提供来源明确的学习入口，不存储或二次发布视频文件。")
        }
        .font(.system(size: 10))
        .foregroundStyle(.secondary)
    }

    private func advance() {
        if currentStep < course.steps.count - 1 { currentStep += 1 }
        else { completedLessons += 1; dismiss() }
    }
}

// MARK: - 社区与活动

struct CommunityHubView: View {
    @State private var joinedChallenge = false
    @State private var likedEntries: Set<Int> = []
    @State private var selectedFeed = "全部"
    @State private var discussionEntry: CommunityEntry?

    private let entries = CommunityEntry.samples
    private let feedFilters = ["全部", "手工原创", "AI 辅助", "馆藏研习"]

    var body: some View {
        ZStack {
            CompetitionPageBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    challengeHero
                    communitySnapshot
                    feedFilter
                    processJournal
                    expertReview
                    DemoNotice(text: "社区作品统一显示创作方式与授权状态，AI 参与内容不会冒充纯手工作品。")
                    Spacer(minLength: 112)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .containerRelativeFrame(.horizontal, alignment: .leading)
            }
        }
        .sheet(item: $discussionEntry) { entry in
            CommunityDiscussionView(entry: entry)
        }
    }

    private var communitySnapshot: some View {
        VStack(alignment: .leading, spacing: 14) {
            SuxiuSectionHeader(eyebrow: "COMMUNITY", title: "本周社区")
            HStack(spacing: 10) {
                communityMetric(value: "6", label: "精选记录")
                communityMetric(value: "4", label: "开放馆藏")
                communityMetric(value: "126", label: "挑战参与")
            }
            Text("从配色试样、针法练习到馆藏纹样拆解，所有内容均标注创作方式与素材来源。")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
    }

    private func communityMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.heritageBlue)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 15))
    }

    private var feedFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(feedFilters, id: \.self) { filter in
                    Button(action: { selectedFeed = filter }) {
                        Text(filter)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selectedFeed == filter ? .white : Color.heritageInk)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedFeed == filter ? Color.heritageBlue : Color.white.opacity(0.78),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var challengeHero: some View {
        ZStack(alignment: .bottomLeading) {
            SuxiuAspectFillImage(name: "Work2", height: 270)
            LinearGradient(colors: [.clear, Color.heritageInk.opacity(0.9)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 9) {
                SuxiuTag(text: "七月创作赛", tint: .orange)
                Text("同一朵荷花，不同针法")
                    .font(.system(size: 25, weight: .bold)).foregroundStyle(.white)
                Text("已有 126 份创作记录 · 7 天后截止")
                    .font(.system(size: 12)).foregroundStyle(.white.opacity(0.72))
                Button(action: { joinedChallenge.toggle() }) {
                    Label(joinedChallenge ? "已加入挑战" : "加入挑战", systemImage: joinedChallenge ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(.white.opacity(0.17), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 23))
    }

    private var processJournal: some View {
        VStack(alignment: .leading, spacing: 16) {
            SuxiuSectionHeader(eyebrow: "PROCESS JOURNAL", title: "创作过程志")
            ForEach(filteredEntries) { entry in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 11).fill(entry.tint.opacity(0.13)).frame(width: 40, height: 40)
                            .overlay(Image(systemName: entry.avatarIcon).foregroundStyle(entry.tint))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.author).font(.system(size: 14, weight: .semibold))
                            Text(entry.stage).font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SuxiuTag(text: entry.creationType, tint: entry.tint)
                    }
                    SuxiuAspectFillImage(name: entry.image, height: 200, cornerRadius: 15)
                    Text(entry.caption).font(.system(size: 13)).foregroundStyle(Color.heritageInk).lineSpacing(3)
                    HStack {
                        Button(action: { toggleLike(entry.id) }) {
                            Label("\(entry.likes + (likedEntries.contains(entry.id) ? 1 : 0))", systemImage: likedEntries.contains(entry.id) ? "heart.fill" : "heart")
                        }
                        Button(action: { discussionEntry = entry }) {
                            Label("交流", systemImage: "bubble.left")
                        }
                        Spacer()
                        if let sourceURL = entry.sourceURL {
                            Link(destination: sourceURL) {
                                Label(entry.sourceTitle, systemImage: "arrow.up.right")
                                    .font(.system(size: 10, weight: .medium))
                            }
                        } else {
                            Text(entry.license)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.heritageBlue)
                }
                .padding(16)
                .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 20))
            }
        }
    }

    private var expertReview: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "quote.opening").font(.system(size: 24)).foregroundStyle(Color.heritageJade)
            VStack(alignment: .leading, spacing: 7) {
                Text("匠人点评示例").font(.system(size: 15, weight: .bold))
                Text("花瓣外缘的线迹可以再顺着生长方向收拢，中心颜色保留得很好。")
                    .font(.system(size: 13)).foregroundStyle(.secondary).lineSpacing(3)
                Text("审核身份 · 演示").font(.system(size: 10, weight: .medium)).foregroundStyle(Color.heritageJade)
            }
        }
        .padding(18)
        .background(Color.heritageJade.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    private func toggleLike(_ id: Int) {
        if likedEntries.contains(id) { likedEntries.remove(id) } else { likedEntries.insert(id) }
    }

    private var filteredEntries: [CommunityEntry] {
        switch selectedFeed {
        case "手工原创", "AI 辅助":
            return entries.filter { $0.creationType == selectedFeed }
        case "馆藏研习":
            return entries.filter { $0.sourceURL != nil }
        default:
            return entries
        }
    }
}

struct CommunityEntry: Identifiable {
    let id: Int
    let author: String
    let stage: String
    let image: String
    let caption: String
    let creationType: String
    let license: String
    let likes: Int
    let avatarIcon: String
    let tint: Color
    let sourceTitle: String
    let sourceURL: URL?

    init(
        id: Int,
        author: String,
        stage: String,
        image: String,
        caption: String,
        creationType: String,
        license: String,
        likes: Int,
        avatarIcon: String,
        tint: Color,
        sourceTitle: String = "社区演示素材",
        sourceURL: String? = nil
    ) {
        self.id = id
        self.author = author
        self.stage = stage
        self.image = image
        self.caption = caption
        self.creationType = creationType
        self.license = license
        self.likes = likes
        self.avatarIcon = avatarIcon
        self.tint = tint
        self.sourceTitle = sourceTitle
        self.sourceURL = sourceURL.flatMap(URL.init(string:))
    }

    static let samples: [CommunityEntry] = [
        .init(id: 1, author: "云针手作", stage: "第 4 天 · 配色调整", image: "Work1", caption: "把 AI 初稿中的高饱和红色换成三组相邻丝线色，花瓣层次柔和了很多。记录了每组色线在自然光和室内光下的差别。", creationType: "AI 辅助", license: "仅展示", likes: 38, avatarIcon: "camera.macro", tint: .heritageBlue),
        .init(id: 2, author: "青简工作室", stage: "第 7 天 · 针法试样", image: "Work3", caption: "同一片叶子分别尝试平针和乱针，记录丝线在不同光线下的变化。最终保留平针轮廓，用少量交错线补暗部。", creationType: "手工原创", license: "署名分享", likes: 57, avatarIcon: "leaf", tint: .heritageJade),
        .init(
            id: 3,
            author: "纹样拆解营",
            stage: "本周研习 · 边饰结构",
            image: "CommunityOpenDetail",
            caption: "从开放馆藏的丝绣局部观察连续回纹、飞鸟与花卉如何共处。练习时只提取边饰节奏，不复制馆藏原作。",
            creationType: "馆藏研习",
            license: "CC0",
            likes: 84,
            avatarIcon: "square.grid.3x3",
            tint: .heritageBlue,
            sourceTitle: "原图 · CC0",
            sourceURL: "https://commons.wikimedia.org/wiki/File:Detail_of_Chinese_silk_embroidery.jpg"
        ),
        .init(
            id: 4,
            author: "金陵花线社",
            stage: "馆藏笔记 · 菊花设色",
            image: "CommunityOpenChrysanthemum",
            caption: "南京博物院展陈中的菊花绣品以克制色阶表现花瓣翻转。我们把画面拆成花心、内瓣、外瓣和枝叶四个观察层。",
            creationType: "馆藏研习",
            license: "CC BY-SA 4.0",
            likes: 96,
            avatarIcon: "camera.macro",
            tint: .heritageJade,
            sourceTitle: "Ecelan · CC BY-SA",
            sourceURL: "https://commons.wikimedia.org/wiki/File:Nanjing_Museum_-_Embroidery_-_Chrysanthemum.jpg"
        ),
        .init(
            id: 5,
            author: "凤纹观察社",
            stage: "馆藏笔记 · 主体与留白",
            image: "CommunityOpenPhoenix",
            caption: "先看凤凰轮廓，再追踪羽毛针脚与竹叶、太阳之间的方向关系。大面积素地让主体更有仪式感，也方便辨认线迹。",
            creationType: "馆藏研习",
            license: "CC BY-SA 4.0",
            likes: 112,
            avatarIcon: "bird",
            tint: .heritageBlue,
            sourceTitle: "Ecelan · CC BY-SA",
            sourceURL: "https://commons.wikimedia.org/wiki/File:Nanjing_Museum_-_Embroidery_-_Phoenix.jpg"
        ),
        .init(
            id: 6,
            author: "衣饰档案局",
            stage: "服饰研习 · 对称构图",
            image: "CommunityOpenWedding",
            caption: "以二十世纪初中国婚礼夹克为观察对象，记录龙凤、花卉与门襟中轴的对称方式。该帖展示开放图片，不代表社区成员拥有原作。",
            creationType: "馆藏研习",
            license: "CC0",
            likes: 73,
            avatarIcon: "tshirt",
            tint: .heritageJade,
            sourceTitle: "Hiart · CC0",
            sourceURL: "https://commons.wikimedia.org/wiki/File:Chinese_wedding_jacket,_early_20th_century,_East-West_Center.JPG"
        )
    ]
}

private struct CommunityDiscussionView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: CommunityEntry

    @State private var draft = ""
    @State private var comments = [
        "我也注意到边缘针脚的方向变化，准备按四个区域分别临摹。",
        "如果先用灰阶观察明暗，再选丝线色，层次会更容易控制。"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(entry.author)
                                .font(.headline)
                            Text(entry.caption)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                        }
                        .padding(16)
                        .background(Color.heritageBlue.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))

                        Text("研习交流")
                            .font(.headline)

                        ForEach(comments.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(index == comments.count - 1 && comments.count > 2 ? Color.heritageJade : Color.heritageBlue)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white)
                                    )
                                Text(comments[index])
                                    .font(.system(size: 13))
                                    .lineSpacing(3)
                                Spacer()
                            }
                        }

                        DemoNotice(text: "讨论内容仅保存在当前页面，关闭后不会上传或保留。")
                    }
                    .padding(20)
                }

                HStack(spacing: 10) {
                    TextField("写下你的观察…", text: $draft, axis: .vertical)
                        .lineLimit(1...3)
                        .textFieldStyle(.roundedBorder)
                    Button("发送", action: sendComment)
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(14)
                .background(.thinMaterial)
            }
            .navigationTitle("作品交流")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func sendComment() {
        let cleaned = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        comments.append(cleaned)
        draft = ""
    }
}

// MARK: - 市场与定制闭环

struct MarketplaceHubView: View {
    @State private var selectedMode = 0
    @State private var selectedOffering: MarketOffering?
    @State private var showCustomFlow = false

    private let modes = ["匠人现货", "AI 定制", "纹样授权"]

    var body: some View {
        ZStack {
            CompetitionPageBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    marketHeader
                    modePicker
                    if selectedMode == 1 { customStudio }
                    else { offeringGrid }
                    productionTimeline
                    DemoNotice(text: "价格、工坊与物流均为比赛演示数据，不产生真实交易。")
                    Spacer(minLength: 112)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .containerRelativeFrame(.horizontal, alignment: .leading)
            }
        }
        .sheet(item: $selectedOffering) { offering in
            OfferingDetailView(offering: offering)
        }
        .sheet(isPresented: $showCustomFlow) {
            CustomOrderDemoView()
        }
    }

    private var marketHeader: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("SU MARKET").font(.system(size: 11, weight: .bold)).tracking(1.8).foregroundStyle(Color.heritageBlue)
            Text("看见一件苏绣的时间")
                .font(.system(size: 28, weight: .bold)).tracking(-0.6)
            Text("材料、针法、工时与制作过程透明呈现。")
                .font(.system(size: 13)).foregroundStyle(.secondary)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 5) {
            ForEach(modes.indices, id: \.self) { index in
                Button(action: { withAnimation(.spring(response: 0.32)) { selectedMode = index } }) {
                    Text(modes[index])
                        .font(.system(size: 13, weight: selectedMode == index ? .semibold : .medium))
                        .foregroundStyle(selectedMode == index ? .white : Color.heritageInk.opacity(0.62))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(selectedMode == index ? Color.heritageBlue : .clear, in: RoundedRectangle(cornerRadius: 11))
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 15))
    }

    private var offeringGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(selectedMode == 0 ? MarketOffering.finished : MarketOffering.licenses) { item in
                Button(action: { selectedOffering = item }) {
                    VStack(alignment: .leading, spacing: 10) {
                        SuxiuAspectFillImage(name: item.image, height: 170, cornerRadius: 16)
                        Text(item.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.heritageInk).lineLimit(2).multilineTextAlignment(.leading)
                        Text(item.craft).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                        HStack {
                            Text(item.price).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Color.heritageBlue)
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.system(size: 11)).foregroundStyle(Color.heritageBlue)
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 19))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var customStudio: some View {
        VStack(alignment: .leading, spacing: 16) {
            SuxiuAspectFillImage(name: "RecommendBanner1", height: 210, cornerRadius: 21)
            Text("把 AI 设计变成一件可制作的绣品")
                .font(.system(size: 20, weight: .bold))
            Text("选择用途与尺寸 → 确认针法和丝线 → 工坊评估 → 样稿确认 → 制作与质检。")
                .font(.system(size: 13)).foregroundStyle(.secondary).lineSpacing(4)
            Button(action: { showCustomFlow = true }) {
                Label("开始定制演示", systemImage: "wand.and.stars")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(Color.heritageBlue, in: RoundedRectangle(cornerRadius: 13))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.80), in: RoundedRectangle(cornerRadius: 22))
    }

    private var productionTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            SuxiuSectionHeader(eyebrow: "C2M WORKFLOW", title: "从样稿到成品")
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(["样稿", "报价", "制作", "质检", "交付"].enumerated()), id: \.offset) { index, title in
                    VStack(spacing: 7) {
                        ZStack {
                            Circle().fill(index == 0 ? Color.heritageBlue : Color.heritageMist).frame(width: 30, height: 30)
                            Text("\(index + 1)").font(.system(size: 11, weight: .bold)).foregroundStyle(index == 0 ? .white : .secondary)
                        }
                        Text(title).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

struct MarketOffering: Identifiable {
    let id: Int
    let title: String
    let image: String
    let craft: String
    let price: String
    let detail: String

    static let finished = [
        MarketOffering(id: 1, title: "牡丹小幅装裱", image: "MarketProduct1", craft: "平针绣 · 约 46 小时", price: "¥ 1,280", detail: "桑蚕丝线，画芯约 24 × 24 cm，包含装裱演示说明。"),
        MarketOffering(id: 2, title: "凤凰主题挂画", image: "MarketProduct2", craft: "套针绣 · 约 72 小时", price: "¥ 2,680", detail: "以多组相邻色表现羽毛层次，适合作为纪念礼赠。"),
        MarketOffering(id: 3, title: "荷花桌面摆件", image: "MarketProduct3", craft: "平针与打籽绣", price: "¥ 860", detail: "小尺寸绣面搭配木质底座，展示花蕊颗粒质感。"),
        MarketOffering(id: 4, title: "山水小屏风", image: "MarketProduct1", craft: "乱针绣 · 约 96 小时", price: "¥ 3,960", detail: "以交错色线塑造远近层次，双面陈列结构。")
    ]

    static let licenses = [
        MarketOffering(id: 11, title: "江南花窗纹样组", image: "RecommendCard1", craft: "个人非商用授权", price: "¥ 39", detail: "包含 4 个可编辑构图与配色说明，授权范围将在下载前确认。"),
        MarketOffering(id: 12, title: "四时花卉纹样组", image: "RecommendCard2", craft: "个人创作授权", price: "¥ 59", detail: "梅、兰、竹、菊四组演示纹样，附建议针法。"),
        MarketOffering(id: 13, title: "团扇留白构图", image: "RecommendCard3", craft: "课堂练习授权", price: "¥ 29", detail: "适合初学者练习平针方向与相邻色过渡。")
    ]
}

struct OfferingDetailView: View {
    let offering: MarketOffering
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SuxiuAspectFillImage(name: offering.image, height: 330, cornerRadius: 23)
                    Text(offering.title).font(.system(size: 27, weight: .bold))
                    Text(offering.price).font(.system(size: 23, weight: .bold, design: .rounded)).foregroundStyle(Color.heritageBlue)
                    Text(offering.detail).font(.system(size: 14)).foregroundStyle(.secondary).lineSpacing(4)
                    Divider()
                    detailRow("制作信息", offering.craft)
                    detailRow("材料", "桑蚕丝线 · 真丝绣底")
                    detailRow("审核状态", "演示内容")
                    DemoNotice(text: "该页面仅用于比赛和软件功能演示，不产生真实交易。")
                }
                .padding(20)
            }
            .background(CompetitionPageBackground())
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack { Text(title).font(.system(size: 13, weight: .semibold)); Spacer(); Text(value).font(.system(size: 12)).foregroundStyle(.secondary) }
    }
}

struct CustomOrderDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    private let steps = ["选择成品用途", "确认尺寸与预算", "匹配工艺方案", "生成演示报价"]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("定制流程").font(.system(size: 29, weight: .bold))
                Text("第 \(step + 1) 步 / \(steps.count)").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.heritageBlue)
                ProgressView(value: Double(step + 1), total: Double(steps.count)).tint(Color.heritageBlue)
                ZStack {
                    RoundedRectangle(cornerRadius: 24).fill(Color.heritageBlue.opacity(0.08))
                    VStack(spacing: 14) {
                        Image(systemName: ["square.resize", "ruler", "point.3.filled.connected.trianglepath.dotted", "doc.text.magnifyingglass"][step])
                            .font(.system(size: 48, weight: .light)).foregroundStyle(Color.heritageBlue)
                        Text(steps[step]).font(.system(size: 20, weight: .bold))
                        Text(step == 3 ? "团扇 · 22 cm · 平针绣 · 预计 36 小时 · 演示价 ¥ 980" : "比赛版本使用预设参数展示完整业务流程。")
                            .font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 20)
                    }
                }
                .frame(height: 300)
                Spacer()
                Button(action: advance) {
                    Text(step == steps.count - 1 ? "完成演示" : "下一步")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.heritageBlue, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
            .background(CompetitionPageBackground())
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("关闭") { dismiss() } } }
        }
    }

    private func advance() { if step < steps.count - 1 { step += 1 } else { dismiss() } }
}
