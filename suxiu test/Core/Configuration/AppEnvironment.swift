import Foundation

enum AppEnvironment {
    static let mockScenarioKey = "developer.mockScenario"
    static let showMockBadgeKey = "developer.showMockBadge"

    static func makeImageGenerator() -> any ImageGenerating {
        let defaults = UserDefaults.standard
        let rawScenario = defaults.string(forKey: mockScenarioKey)
        let scenario = rawScenario.flatMap(MockScenario.init(rawValue:)) ?? .success
        let showBadge = defaults.object(forKey: showMockBadgeKey) == nil
            ? true
            : defaults.bool(forKey: showMockBadgeKey)

        return MockImageGenerator(
            configuration: MockConfiguration(
                scenario: scenario,
                showMockBadge: showBadge
            )
        )
    }

    static var shouldShowMockBadge: Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: showMockBadgeKey) != nil else { return true }
        return defaults.bool(forKey: showMockBadgeKey)
    }
}
