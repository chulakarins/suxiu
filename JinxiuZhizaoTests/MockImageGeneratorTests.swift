import XCTest
@testable import JinxiuZhizao

@MainActor
final class MockImageGeneratorTests: XCTestCase {
    func testKeywordSelectionMatchesExpectedAsset() {
        XCTAssertEqual(
            MockImageCatalog.selectEntry(for: "荷塘里有一只白鹤").resourceName,
            "mock_crane_lotus_01"
        )
        XCTAssertEqual(
            MockImageCatalog.selectEntry(for: "花间白猫").resourceName,
            "mock_white_cat_01"
        )
    }

    func testUnknownPromptHasStableFallback() {
        let prompt = "一段没有预设关键词的独特描述"
        let first = MockImageCatalog.selectEntry(for: prompt)
        let second = MockImageCatalog.selectEntry(for: prompt)
        XCTAssertEqual(first, second)
        XCTAssertTrue(first.resourceName.hasPrefix("mock_default_"))
    }

    func testFastSuccessLoadsPackagedImage() async throws {
        let generator = MockImageGenerator(
            configuration: MockConfiguration(scenario: .fastSuccess)
        )

        let payload = try await generator.generate(
            prompt: "牡丹和蝴蝶",
            referenceImageData: nil,
            onProgress: { _ in }
        )

        XCTAssertEqual(payload.provider, "mock")
        XCTAssertTrue(payload.isMock)
        XCTAssertGreaterThan(payload.imageData.count, 100_000)
    }

    func testNormalSuccessTakesBetweenFiveAndEightSeconds() async throws {
        let generator = MockImageGenerator(
            configuration: MockConfiguration(scenario: .success)
        )
        let start = Date()

        _ = try await generator.generate(
            prompt: "荷塘白鹤",
            referenceImageData: nil,
            onProgress: { _ in }
        )

        let elapsed = Date().timeIntervalSince(start)
        XCTAssertGreaterThanOrEqual(elapsed, 4.9)
        XCTAssertLessThanOrEqual(elapsed, 8.5)
    }

    func testAllNineteenAssetsArePackaged() {
        let allEntries = MockImageCatalog.entries + MockImageCatalog.fallbackEntries
        XCTAssertEqual(allEntries.count, 19)

        for entry in allEntries {
            let url = Bundle.main.url(
                forResource: entry.resourceName,
                withExtension: entry.fileExtension
            )
            XCTAssertNotNil(url, "缺少素材：\(entry.resourceName)")
        }
    }

    func testOfflineScenarioIsDeterministic() async {
        let generator = MockImageGenerator(
            configuration: MockConfiguration(scenario: .offline)
        )

        do {
            _ = try await generator.generate(
                prompt: "白猫",
                referenceImageData: nil,
                onProgress: { _ in }
            )
            XCTFail("离线场景应抛出错误")
        } catch let error as GenerationError {
            guard case .offline = error else {
                return XCTFail("应返回 offline，实际为 \(error)")
            }
        } catch {
            XCTFail("返回了非 GenerationError：\(error)")
        }
    }

    func testServiceFailureOccursAtKnownStage() async {
        let generator = MockImageGenerator(
            configuration: MockConfiguration(scenario: .serviceFailure)
        )

        do {
            _ = try await generator.generate(
                prompt: "江南水乡",
                referenceImageData: nil,
                onProgress: { _ in }
            )
            XCTFail("服务失败场景应抛出错误")
        } catch let error as GenerationError {
            guard case .serviceUnavailable = error else {
                return XCTFail("应返回 serviceUnavailable，实际为 \(error)")
            }
        } catch {
            XCTFail("返回了非 GenerationError：\(error)")
        }
    }

    func testSlowTaskCanBeCancelled() async {
        let generator = MockImageGenerator(
            configuration: MockConfiguration(scenario: .slowSuccess)
        )
        let task = Task {
            try await generator.generate(
                prompt: "月下玉兔",
                referenceImageData: nil,
                onProgress: { _ in }
            )
        }

        try? await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("取消任务后不应返回图片")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("取消应返回 CancellationError，实际为 \(error)")
        }
    }
}
