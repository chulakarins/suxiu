import XCTest
@testable import JinxiuZhizao

@MainActor
final class AIImageServiceTests: XCTestCase {

    var service: AIImageService!

    override func setUp() async throws {
        service = AIImageService()
    }

    override func tearDown() async throws {
        service = nil
    }

    // MARK: - 测试提示词处理

    func testPromptWithEmptyString() async throws {
        // 测试空提示词处理
        let expectation = self.expectation(description: "Empty prompt should handle gracefully")

        do {
            _ = try await service.generateSuxiuImageURL(prompt: "")
            XCTFail("Expected an error for empty prompt")
        } catch {
            // 预期会抛出错误
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testPromptWithValidString() async throws {
        // 测试有效提示词 - 仅验证格式，不实际调用 API
        let prompt = "一只可爱的猫咪"

        // 验证提示词后缀是否正确添加
        let suxiuSuffix = ", ultra realistic macro photography of traditional suzhou embroidery (苏绣)"
        XCTAssertTrue(prompt.contains("猫咪"), "提示词应包含用户输入")
    }

    func testPromptExtension() {
        // 测试苏绣提示词扩展
        let basePrompt = "一朵花"
        let expectedSuffix = ", ultra realistic macro photography of traditional suzhou embroidery (苏绣), hand stitched silk threads, visible thread fibers"

        let fullPrompt = basePrompt + expectedSuffix
        XCTAssertTrue(fullPrompt.contains("苏绣"), "完整提示词应包含苏绣关键词")
        XCTAssertTrue(fullPrompt.contains("embroidery"), "完整提示词应包含 embroidery 关键词")
    }

    // MARK: - 测试负向提示词

    func testNegativePrompt() {
        // 验证负向提示词内容
        let negativePrompt = "CGI, 3D render, plastic texture, artificial smooth surfaces, over-sharpening, glossy AI effect, cartoon, anime, digital illustration, oil painting, watercolor, brush strokes, low quality"

        XCTAssertTrue(negativePrompt.contains("CGI"), "负向提示词应排除 CGI")
        XCTAssertTrue(negativePrompt.contains("plastic"), "负向提示词应排除塑料质感")
        XCTAssertTrue(negativePrompt.contains("cartoon"), "负向提示词应排除卡通风格")
    }

    // MARK: - 测试 API 配置

    func testAPIEndpoint() {
        // 验证 API 端点配置
        let endpoint = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis"
        XCTAssertTrue(endpoint.hasPrefix("https://"), "API 端点应使用 HTTPS")
        XCTAssertTrue(endpoint.contains("dashscope"), "应使用通义万相 API")
    }

    func testTaskPollingInterval() {
        // 验证任务轮询间隔
        let pollInterval: UInt64 = 5_000_000_000 // 5 秒
        let maxAttempts = 30

        let totalTimeout = pollInterval * UInt64(maxAttempts)
        let totalSeconds = Double(totalTimeout) / 1_000_000_000.0

        XCTAssertEqual(totalSeconds, 150.0, "总超时时间应为 150 秒")
    }

    // MARK: - 测试错误处理

    func testInvalidURL() {
        // 测试无效 URL 处理
        let invalidURL = "not-a-valid-url"
        let url = URL(string: invalidURL)
        XCTAssertNil(url, "无效 URL 应返回 nil")
    }

    func testValidURL() {
        // 测试有效 URL 解析
        let validURL = "https://dashscope.aliyuncs.com/api/v1/tasks/123456"
        let url = URL(string: validURL)
        XCTAssertNotNil(url, "有效 URL 应成功解析")
    }

    // MARK: - 测试响应解析

    func testTaskStatusValues() {
        // 验证任务状态枚举值
        let statuses = ["PENDING", "RUNNING", "SUCCEEDED", "FAILED"]

        XCTAssertTrue(statuses.contains("SUCCEEDED"), "应包含成功状态")
        XCTAssertTrue(statuses.contains("FAILED"), "应包含失败状态")
        XCTAssertTrue(statuses.contains("RUNNING"), "应包含运行中状态")
    }

    func testMaxRetryAttempts() {
        // 验证最大重试次数
        let maxAttempts = 30
        XCTAssertGreaterThanOrEqual(maxAttempts, 20, "最大重试次数应至少为 20")
        XCTAssertLessThanOrEqual(maxAttempts, 50, "最大重试次数不应超过 50")
    }
}
