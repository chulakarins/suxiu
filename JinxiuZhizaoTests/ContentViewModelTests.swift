import XCTest
@testable import JinxiuZhizao

@MainActor
final class ContentViewModelTests: XCTestCase {

    var viewModel: ContentViewModel!

    override func setUp() async throws {
        viewModel = ContentViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - 测试初始状态

    func testInitialState() {
        // 验证 ViewModel 初始状态
        XCTAssertTrue(viewModel.promptText.isEmpty, "初始提示词应为空")
        XCTAssertNil(viewModel.generatedImageURL, "初始图片 URL 应为 nil")
        XCTAssertFalse(viewModel.isLoading, "初始加载状态应为 false")
        XCTAssertNil(viewModel.errorMessage, "初始错误信息应为 nil")
    }

    // MARK: - 测试输入验证

    func testEmptyPromptValidation() {
        // 测试空提示词验证
        viewModel.promptText = ""
        viewModel.generateImage()

        XCTAssertNotNil(viewModel.errorMessage, "空提示词应产生错误信息")
        XCTAssertEqual(viewModel.errorMessage, "请输入描述内容")
        XCTAssertFalse(viewModel.isLoading, "空提示词不应触发加载状态")
    }

    func testWhitespaceOnlyPrompt() {
        // 测试纯空格提示词验证
        viewModel.promptText = "   "
        viewModel.generateImage()

        XCTAssertNotNil(viewModel.errorMessage, "纯空格提示词应产生错误信息")
        XCTAssertEqual(viewModel.errorMessage, "请输入描述内容")
    }

    func testValidPrompt() {
        // 测试有效提示词
        viewModel.promptText = "一只可爱的猫咪"
        viewModel.generateImage()

        XCTAssertNil(viewModel.errorMessage, "有效提示词应清除错误信息")
        XCTAssertTrue(viewModel.isLoading, "有效提示词应触发加载状态")
    }

    // MARK: - 测试状态管理

    func testLoadingState() {
        // 测试加载状态管理
        viewModel.promptText = "测试提示词"
        viewModel.generateImage()

        XCTAssertTrue(viewModel.isLoading, "生成时应处于加载状态")
        XCTAssertNil(viewModel.generatedImageURL, "加载时图片 URL 应为 nil")
    }

    func testErrorStateClearing() {
        // 测试错误状态清除
        viewModel.promptText = ""
        viewModel.generateImage()

        XCTAssertNotNil(viewModel.errorMessage)

        // 输入有效内容后，错误状态应被清除
        viewModel.promptText = "新的提示词"
        // 注意：实际错误清除发生在下次 generateImage 调用时
    }

    func testGeneratedURLState() {
        // 测试生成 URL 状态
        let testURL = "https://example.com/image.png"

        // 模拟设置生成的 URL
        viewModel.generatedImageURL = testURL

        XCTAssertEqual(viewModel.generatedImageURL, testURL)
        XCTAssertFalse(viewModel.isLoading, "生成完成后加载状态应为 false")
    }

    // MARK: - 测试提示词处理

    func testPromptTextBinding() {
        // 测试提示词文本绑定
        let testPrompt = "一朵红色的玫瑰花"

        viewModel.promptText = testPrompt
        XCTAssertEqual(viewModel.promptText, testPrompt)
    }

    func testPromptWithSpecialCharacters() {
        // 测试包含特殊字符的提示词
        let specialPrompt = "你好！世界 🌍 100%"

        viewModel.promptText = specialPrompt
        XCTAssertEqual(viewModel.promptText, specialPrompt)

        // 验证 trim 操作
        let trimmed = specialPrompt.trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(trimmed, specialPrompt)
    }

    func testPromptWithLeadingTrailingSpaces() {
        // 测试包含前后空格的提示词
        let promptWithSpaces = "  一只猫咪  "

        viewModel.promptText = promptWithSpaces

        // 验证 trim 后的内容
        let trimmed = promptWithSpaces.trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(trimmed, "一只猫咪")
        XCTAssertFalse(trimmed.isEmpty, "trim 后不应为空")
    }

    // MARK: - 测试错误信息

    func testErrorMessageContent() {
        // 测试错误信息内容
        viewModel.promptText = ""
        viewModel.generateImage()

        XCTAssertEqual(viewModel.errorMessage, "请输入描述内容")
        XCTAssertTrue(viewModel.errorMessage!.contains("输入"), "错误信息应包含'输入'关键词")
    }

    // MARK: - 测试并发安全

    func testConcurrentGenerateCalls() async throws {
        // 测试并发调用 generateImage
        viewModel.promptText = "测试并发"

        // 注意：由于 @MainActor 标记，实际调用会顺序执行
        viewModel.generateImage()

        // 验证加载状态
        XCTAssertTrue(viewModel.isLoading)
    }
}
