import Foundation

struct MockImageGenerator: ImageGenerating {
    let configuration: MockConfiguration

    func generate(
        prompt: String,
        referenceImageData: Data?,
        onProgress: @escaping GenerationProgressHandler
    ) async throws -> GeneratedImagePayload {
        let cleaned = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw GenerationError.emptyPrompt }
        guard configuration.scenario != .offline else { throw GenerationError.offline }

        _ = referenceImageData
        let timing = timingForCurrentRun()
        await onProgress(.validating)
        try await pause(milliseconds: 250)

        await onProgress(.queued)
        try await pause(milliseconds: timing.queueDelay)

        for progress in [0.15, 0.35, 0.55, 0.75, 0.90] {
            if configuration.scenario == .serviceFailure, progress >= 0.55 {
                throw GenerationError.serviceUnavailable
            }
            await onProgress(.generating(progress))
            try Task.checkCancellation()
            try await pause(milliseconds: timing.stepDelay)
        }

        if configuration.scenario == .timeout {
            try await pause(milliseconds: 1_500)
            throw GenerationError.timedOut
        }

        await onProgress(.downloading)
        try await pause(milliseconds: 200)

        let entry = MockImageCatalog.selectEntry(for: cleaned)
        guard let url = resourceURL(for: entry) else {
            throw GenerationError.missingMockAsset(entry.resourceName)
        }

        return GeneratedImagePayload(
            providerTaskID: "mock-\(UUID().uuidString)",
            provider: "mock",
            imageData: try Data(contentsOf: url),
            fileExtension: entry.fileExtension,
            isMock: true
        )
    }

    private func resourceURL(for entry: MockImageEntry) -> URL? {
        let subdirectories = ["MockImages", "Resources/MockImages"]
        for subdirectory in subdirectories {
            if let url = Bundle.main.url(
                forResource: entry.resourceName,
                withExtension: entry.fileExtension,
                subdirectory: subdirectory
            ) {
                return url
            }
        }
        return Bundle.main.url(
            forResource: entry.resourceName,
            withExtension: entry.fileExtension
        )
    }

    private func timingForCurrentRun() -> (queueDelay: Int, stepDelay: Int) {
        switch configuration.scenario {
        case .success:
            // validating 250ms + queue + five steps + downloading 200ms
            // 共同组成每次随机约 5-8 秒的完整演示流程。
            let targetDuration = Int.random(in: 5_000...8_000)
            let queueDelay = 600
            let stepDelay = max(1, (targetDuration - 1_050) / 5)
            return (queueDelay, stepDelay)
        case .fastSuccess:
            return (50, 50)
        case .slowSuccess:
            return (1_500, 2_200)
        default:
            return (500, 420)
        }
    }

    private func pause(milliseconds: Int) async throws {
        try await Task.sleep(for: .milliseconds(milliseconds))
    }
}
