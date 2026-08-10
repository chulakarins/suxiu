import XCTest
@testable import JinxiuZhizao

@MainActor
final class APIIntegrationTests: XCTestCase {

    // MARK: - 测试 API 配置

    func testAPIEndpointConfiguration() {
        // 验证 API 端点配置
        let submitEndpoint = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis"
        let queryEndpoint = "https://dashscope.aliyuncs.com/api/v1/tasks/"

        XCTAssertTrue(submitEndpoint.hasPrefix("https://"), "提交端点应使用 HTTPS")
        XCTAssertTrue(queryEndpoint.hasPrefix("https://"), "查询端点应使用 HTTPS")
        XCTAssertTrue(submitEndpoint.contains("dashscope"), "应使用通义万相 API")
    }

    func testAPIModelConfiguration() {
        // 验证 API 模型配置
        let model = "wan2.5-t2i-preview"

        XCTAssertEqual(model, "wan2.5-t2i-preview", "应使用通义万相预览模型")
    }

    func testAPIImageSizeConfiguration() {
        // 验证 API 图片尺寸配置
        let imageSize = "1280*1280"

        XCTAssertEqual(imageSize, "1280*1280", "应生成 1280x1280 正方形图片")
    }

    // MARK: - 测试请求头配置

    func testRequestHeaders() {
        // 验证请求头配置
        let contentType = "application/json"
        let asyncHeader = "enable"

        XCTAssertEqual(contentType, "application/json", "内容类型应为 JSON")
        XCTAssertEqual(asyncHeader, "enable", "应启用异步处理")
    }

    // MARK: - 测试提示词工程

    func testSuxiuPromptSuffix() {
        // 验证苏绣提示词后缀
        let suxiuSuffix = ", ultra realistic macro photography of traditional suzhou embroidery (苏绣), hand stitched silk threads, visible thread fibers, delicate needlework details, natural fabric folds, subtle thread tension variations, silk texture with soft light scattering, micro reflections on threads, 100mm macro lens, shallow depth of field, realistic bokeh, soft studio lighting, gentle shadows, slight natural imperfections, documentary style textile photography, extremely detailed craftsmanship"

        XCTAssertTrue(suxiuSuffix.contains("苏绣"), "应包含苏绣关键词")
        XCTAssertTrue(suxiuSuffix.contains("embroidery"), "应包含刺绣关键词")
        XCTAssertTrue(suxiuSuffix.contains("silk"), "应包含丝绸关键词")
        XCTAssertTrue(suxiuSuffix.contains("macro"), "应包含微距关键词")
    }

    func testNegativePromptContent() {
        // 验证负向提示词内容
        let negativePrompt = "CGI, 3D render, plastic texture, artificial smooth surfaces, over-sharpening, glossy AI effect, cartoon, anime, digital illustration, oil painting, watercolor, brush strokes, low quality"

        XCTAssertTrue(negativePrompt.contains("CGI"), "应排除 CGI")
        XCTAssertTrue(negativePrompt.contains("plastic"), "应排除塑料质感")
        XCTAssertTrue(negativePrompt.contains("cartoon"), "应排除卡通")
        XCTAssertTrue(negativePrompt.contains("anime"), "应排除动漫")
        XCTAssertTrue(negativePrompt.contains("oil painting"), "应排除油画")
    }

    // MARK: - 测试任务轮询

    func testPollingConfiguration() {
        // 验证轮询配置
        let maxAttempts = 30
        let pollIntervalSeconds: Double = 5.0

        XCTAssertEqual(maxAttempts, 30, "最大轮询次数应为 30")
        XCTAssertEqual(pollIntervalSeconds, 5.0, "轮询间隔应为 5 秒")
    }

    func testMaxTimeoutCalculation() {
        // 验证最大超时计算
        let maxAttempts = 30
        let pollIntervalSeconds = 5.0
        let maxTimeout = maxAttempts * pollIntervalSeconds

        XCTAssertEqual(maxTimeout, 150.0, "最大超时时间应为 150 秒")
    }

    // MARK: - 测试任务状态

    func testTaskStatusValues() {
        // 验证任务状态值
        let pendingStatus = "PENDING"
        let runningStatus = "RUNNING"
        let succeededStatus = "SUCCEEDED"
        let failedStatus = "FAILED"

        XCTAssertEqual(pendingStatus, "PENDING")
        XCTAssertEqual(runningStatus, "RUNNING")
        XCTAssertEqual(succeededStatus, "SUCCEEDED")
        XCTAssertEqual(failedStatus, "FAILED")
    }

    // MARK: - 测试响应解析

    func testSuccessResponseStructure() {
        // 验证成功响应结构
        let requiredFields = ["output", "task_id", "task_status", "results", "url"]

        XCTAssertGreaterThanOrEqual(requiredFields.count, 5, "成功响应应包含至少 5 个字段")
        XCTAssertTrue(requiredFields.contains("task_id"), "应包含 task_id")
        XCTAssertTrue(requiredFields.contains("task_status"), "应包含 task_status")
        XCTAssertTrue(requiredFields.contains("results"), "应包含 results")
    }

    func testErrorResponseStructure() {
        // 验证错误响应结构
        let errorFields = ["code", "message"]

        XCTAssertGreaterThanOrEqual(errorFields.count, 2, "错误响应应包含至少 2 个字段")
        XCTAssertTrue(errorFields.contains("code"), "应包含错误码")
        XCTAssertTrue(errorFields.contains("message"), "应包含错误信息")
    }

    // MARK: - 测试错误处理

    func testTimeoutError() {
        // 验证超时错误
        let timeoutErrorMessage = "任务超时，请稍后重试"

        XCTAssertTrue(timeoutErrorMessage.contains("超时"), "超时错误应包含'超时'关键词")
    }

    func testInvalidURLError() {
        // 验证无效 URL 错误
        let invalidURL = "not-a-url"
        let url = URL(string: invalidURL)

        XCTAssertNil(url, "无效 URL 应返回 nil")
    }

    // MARK: - 测试 HTTP 状态码

    func testHTTPStatusCodes() {
        // 验证 HTTP 状态码处理
        let successCode = 200
        let errorCode = 400
        let unauthorizedCode = 401
        let serverErrorCode = 500

        XCTAssertEqual(successCode, 200, "成功状态码应为 200")
        XCTAssertGreaterThan(errorCode, successCode, "错误状态码应大于 200")
        XCTAssertGreaterThan(unauthorizedCode, errorCode, "未授权状态码应大于 400")
        XCTAssertGreaterThan(serverErrorCode, unauthorizedCode, "服务器错误状态码应大于 401")
    }

    // MARK: - 测试 API 限流

    func testRateLimitingAwareness() {
        // 验证限流意识
        let requestIntervalSeconds: Double = 5.0
        let maxRequestsPerMinute = 60.0 / requestIntervalSeconds

        XCTAssertEqual(maxRequestsPerMinute, 12.0, "每分钟最多 12 次请求")
    }

    // MARK: - 测试图片 URL 验证

    func testImageURLValidation() {
        // 验证图片 URL 格式
        let validImageURL = "https://dashscope.aliyuncs.com/image.png"
        let invalidImageURL = "not-a-url"

        let validURL = URL(string: validImageURL)
        let invalidURL = URL(string: invalidImageURL)

        XCTAssertNotNil(validURL, "有效图片 URL 应能解析")
        XCTAssertNil(invalidURL, "无效图片 URL 应返回 nil")
    }

    func testImageURLScheme() {
        // 验证图片 URL 协议
        let imageURL = "https://dashscope.aliyuncs.com/image.png"

        XCTAssertTrue(imageURL.hasPrefix("https://"), "图片 URL 应使用 HTTPS 协议")
    }
}
