import Foundation

enum MockScenario: String, CaseIterable, Identifiable, Sendable {
    case success
    case fastSuccess
    case slowSuccess
    case serviceFailure
    case timeout
    case offline

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .success: return "正常成功"
        case .fastSuccess: return "快速成功"
        case .slowSuccess: return "慢速成功"
        case .serviceFailure: return "服务失败"
        case .timeout: return "任务超时"
        case .offline: return "离线"
        }
    }
}

struct MockConfiguration: Sendable {
    var scenario: MockScenario = .success
    var showMockBadge = true
}
