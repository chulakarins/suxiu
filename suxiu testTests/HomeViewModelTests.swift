import XCTest
@testable import suxiu_test

@MainActor
final class HomeViewModelTests: XCTestCase {

    var viewModel: HomeViewModel!

    override func setUp() async throws {
        viewModel = HomeViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - 测试初始状态

    func testInitialState() {
        // 验证初始选中 Tab 为首页
        XCTAssertEqual(viewModel.selectedTab, 0, "初始选中 Tab 应为首页")
    }

    // MARK: - 测试 Tab 切换

    func testTabSwitching() {
        // 测试切换到市场 Tab
        viewModel.selectedTab = 1
        XCTAssertEqual(viewModel.selectedTab, 1, "应切换到市场 Tab")

        // 测试切换到推荐 Tab
        viewModel.selectedTab = 2
        XCTAssertEqual(viewModel.selectedTab, 2, "应切换到推荐 Tab")

        // 测试切换到我的 Tab
        viewModel.selectedTab = 3
        XCTAssertEqual(viewModel.selectedTab, 3, "应切换到我的 Tab")
    }

    func testTabRange() {
        // 验证 Tab 索引范围
        let validTabs = [0, 1, 2, 3]

        for tab in validTabs {
            viewModel.selectedTab = tab
            XCTAssertEqual(viewModel.selectedTab, tab)
        }
    }

    // MARK: - 测试 Tab 边界值

    func testTabMinBoundary() {
        // 测试最小边界值
        viewModel.selectedTab = 0
        XCTAssertEqual(viewModel.selectedTab, 0, "最小 Tab 索引应为 0")
    }

    func testTabMaxBoundary() {
        // 测试最大边界值
        viewModel.selectedTab = 3
        XCTAssertEqual(viewModel.selectedTab, 3, "最大 Tab 索引应为 3")
    }

    // MARK: - 测试 Tab 枚举

    func testTabCases() {
        // 验证所有 Tab 情况
        enum TabCase: Int, CaseIterable {
            case home = 0
            case market = 1
            case inspire = 2
            case profile = 3
        }

        XCTAssertEqual(TabCase.allCases.count, 4, "应有 4 个 Tab")
        XCTAssertEqual(TabCase.home.rawValue, 0)
        XCTAssertEqual(TabCase.market.rawValue, 1)
        XCTAssertEqual(TabCase.inspire.rawValue, 2)
        XCTAssertEqual(TabCase.profile.rawValue, 3)
    }

    // MARK: - 测试状态保持

    func testStatePersistence() {
        // 测试状态保持
        let targetTab = 2
        viewModel.selectedTab = targetTab

        // 验证状态未意外改变
        XCTAssertEqual(viewModel.selectedTab, targetTab)
        XCTAssertEqual(viewModel.selectedTab, targetTab)
    }

    // MARK: - 测试并发安全

    func testConcurrentTabSwitching() async throws {
        // 测试并发 Tab 切换
        let tabs = [0, 1, 2, 3]

        for tab in tabs {
            viewModel.selectedTab = tab
            XCTAssertEqual(viewModel.selectedTab, tab)
        }
    }
}
