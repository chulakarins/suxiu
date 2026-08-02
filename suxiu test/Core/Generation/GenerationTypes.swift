import Foundation

enum GenerationStage: Equatable, Sendable {
    case idle
    case validating
    case queued
    case generating(Double)
    case downloading
    case saving
    case completed
    case failed
    case cancelled
}

struct GeneratedImagePayload: Sendable {
    let providerTaskID: String
    let provider: String
    let imageData: Data
    let fileExtension: String
    let isMock: Bool
}

typealias GenerationProgressHandler =
    @Sendable (GenerationStage) async -> Void

protocol ImageGenerating: Sendable {
    func generate(
        prompt: String,
        referenceImageData: Data?,
        onProgress: @escaping GenerationProgressHandler
    ) async throws -> GeneratedImagePayload
}

enum GenerationError: LocalizedError, Sendable {
    case emptyPrompt
    case offline
    case serviceUnavailable
    case rateLimited
    case timedOut
    case invalidResponse
    case missingMockAsset(String)

    var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "请输入你想生成的苏绣画面"
        case .offline:
            return "当前网络不可用，请检查网络后重试"
        case .serviceUnavailable:
            return "图片生成服务暂时不可用，请稍后重试"
        case .rateLimited:
            return "生成请求较多，请稍后再试"
        case .timedOut:
            return "生成时间过长，请重新尝试"
        case .invalidResponse:
            return "没有获得有效的图片结果"
        case .missingMockAsset(let name):
            return "缺少演示素材：\(name)"
        }
    }
}
