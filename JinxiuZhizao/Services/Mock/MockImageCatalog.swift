import Foundation

struct MockImageEntry: Equatable, Sendable {
    let resourceName: String
    let fileExtension: String
    let keywords: [String]
    let title: String
}

enum MockImageCatalog {
    static let entries: [MockImageEntry] = [
        .init(resourceName: "mock_crane_lotus_01", fileExtension: "jpg", keywords: ["白鹤", "仙鹤", "鹤", "荷花", "莲花", "荷塘"], title: "荷塘白鹤"),
        .init(resourceName: "mock_peony_butterfly_01", fileExtension: "jpg", keywords: ["牡丹", "蝴蝶", "富贵", "花蝶"], title: "牡丹花蝶"),
        .init(resourceName: "mock_white_cat_01", fileExtension: "jpg", keywords: ["猫", "小猫", "白猫", "宠物"], title: "花间白猫"),
        .init(resourceName: "mock_jiangnan_landscape_01", fileExtension: "jpg", keywords: ["江南", "山水", "园林", "小桥", "流水", "水乡"], title: "江南水乡"),
        .init(resourceName: "mock_koi_lotus_01", fileExtension: "jpg", keywords: ["锦鲤", "金鱼", "鱼", "荷叶", "池塘"], title: "锦鲤戏莲"),
        .init(resourceName: "mock_plum_magpie_01", fileExtension: "jpg", keywords: ["梅花", "喜鹊", "报春", "冬天"], title: "喜上梅梢"),
        .init(resourceName: "mock_bamboo_sparrow_01", fileExtension: "jpg", keywords: ["竹子", "竹叶", "麻雀", "小鸟", "清雅"], title: "竹影雀鸣"),
        .init(resourceName: "mock_orchid_01", fileExtension: "jpg", keywords: ["兰花", "幽兰", "兰草", "文人"], title: "空谷幽兰"),
        .init(resourceName: "mock_portrait_01", fileExtension: "jpg", keywords: ["人物", "女孩", "女性", "仕女", "肖像", "人像", "汉服"], title: "江南仕女"),
        .init(resourceName: "mock_garden_01", fileExtension: "jpg", keywords: ["苏州园林", "园林", "亭子", "月洞门", "庭院", "古建筑"], title: "园林春色"),
        .init(resourceName: "mock_phoenix_01", fileExtension: "jpg", keywords: ["凤凰", "百鸟", "华丽", "金色", "祥瑞"], title: "锦羽凤凰"),
        .init(resourceName: "mock_dragon_01", fileExtension: "jpg", keywords: ["龙", "祥龙", "云龙", "神兽", "力量"], title: "云海祥龙"),
        .init(resourceName: "mock_wedding_01", fileExtension: "jpg", keywords: ["婚礼", "婚庆", "喜字", "新婚", "情侣", "礼物", "喜庆"], title: "鸾凤和鸣"),
        .init(resourceName: "mock_moon_rabbit_01", fileExtension: "jpg", keywords: ["兔子", "玉兔", "月亮", "中秋", "月宫"], title: "月下玉兔"),
        .init(resourceName: "mock_tea_still_life_01", fileExtension: "jpg", keywords: ["茶", "茶具", "茶壶", "静物", "雅集", "生活"], title: "清茶雅韵"),
        .init(resourceName: "mock_abstract_wave_01", fileExtension: "jpg", keywords: ["抽象", "纹样", "波浪", "现代", "蓝色", "装饰"], title: "丝路流光")
    ]

    static let fallbackEntries: [MockImageEntry] = [
        .init(resourceName: "mock_default_floral_01", fileExtension: "jpg", keywords: [], title: "默认花卉团纹"),
        .init(resourceName: "mock_default_bird_01", fileExtension: "jpg", keywords: [], title: "默认花鸟小景"),
        .init(resourceName: "mock_default_landscape_01", fileExtension: "jpg", keywords: [], title: "默认远山烟波")
    ]

    static func selectEntry(for prompt: String) -> MockImageEntry {
        let normalized = prompt
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let scored = entries.map { entry in
            let score = entry.keywords.reduce(into: 0) { result, keyword in
                if normalized.contains(keyword.lowercased()) {
                    result += 1
                }
            }
            return (entry: entry, score: score)
        }

        let highestScore = scored.map(\.score).max() ?? 0
        guard highestScore > 0 else {
            return fallbackEntries[stableIndex(for: normalized, count: fallbackEntries.count)]
        }

        let winners = scored
            .filter { $0.score == highestScore }
            .map(\.entry)
        return winners[stableIndex(for: normalized, count: winners.count)]
    }

    static func stableIndex(for text: String, count: Int) -> Int {
        guard count > 0 else { return 0 }

        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return Int(hash % UInt64(count))
    }
}
