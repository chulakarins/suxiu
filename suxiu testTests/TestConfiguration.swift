import Foundation

/// 测试配置
///
/// 此文件包含测试配置信息
public struct TestConfiguration {
    /// API 测试配置
    struct API {
        static let baseURL = "https://dashscope.aliyuncs.com/api/v1"
        static let imageSynthesisEndpoint = "/services/aigc/text2image/image-synthesis"
        static let taskQueryPrefix = "/tasks/"
        static let model = "wan2.5-t2i-preview"
        static let imageSize = "1280*1280"
        static let maxPollAttempts = 30
        static let pollIntervalSeconds: Double = 5.0
    }

    /// UI 测试配置
    struct UI {
        /// 颜色配置
        struct Colors {
            static let backgroundPrimary = (red: 0.945, green: 0.957, blue: 0.976)
            static let backgroundSecondary = (red: 0.910, green: 0.929, blue: 0.961)
            static let accentBlue = (red: 0.2, green: 0.48, blue: 0.95)
        }

        /// 间距配置
        struct Spacing {
            static let xs: CGFloat = 4
            static let sm: CGFloat = 8
            static let md: CGFloat = 16
            static let lg: CGFloat = 24
            static let xl: CGFloat = 32
        }

        /// 圆角配置
        struct CornerRadius {
            static let button: CGFloat = 8
            static let card: CGFloat = 16
            static let inputField: CGFloat = 22
            static let tabBar: CGFloat = 45
        }
    }

    /// 测试超时配置
    struct Timeout {
        static let defaultTimeout: TimeInterval = 5.0
        static let networkTimeout: TimeInterval = 30.0
        static let animationTimeout: TimeInterval = 10.0
    }
}
