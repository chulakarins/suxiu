import XCTest

final class SuxiuMotionUITests: XCTestCase {
    private var viewportDockSamples: [String] = []

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPrimaryTabsKeepNavigationUsable() {
        let app = launchApp()

        let learningTab = app.buttons["学习"]
        XCTAssertTrue(learningTab.waitForExistence(timeout: 3))
        learningTab.tap()
        XCTAssertTrue(app.navigationBars.staticTexts["苏绣学习馆"].waitForExistence(timeout: 2))

        app.buttons["社区"].tap()
        XCTAssertTrue(app.navigationBars.staticTexts["绣友社区"].waitForExistence(timeout: 2))

        app.buttons["文化"].tap()
        XCTAssertTrue(app.navigationBars.staticTexts["苏绣数字博物馆"].waitForExistence(timeout: 2))
    }

    func testFastGenerationReachesResultWithoutBlankState() {
        let app = launchApp(extraArguments: [
            "-developer.mockScenario", "fastSuccess"
        ])

        let aiEntry = app.buttons["打开 AI 创作工坊"]
        XCTAssertTrue(aiEntry.waitForExistence(timeout: 3))
        aiEntry.tap()

        let promptField = app.textViews["ai-prompt-composer"]
        XCTAssertTrue(promptField.waitForExistence(timeout: 3))
        promptField.tap()
        promptField.typeText("荷塘白鹤")

        let generateButton = app.buttons["开始生成"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 2))
        generateButton.tap()

        XCTAssertTrue(app.staticTexts["AI 工艺建议"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["演示素材"].exists)
    }

    func testComposerStartsDockedToViewport() {
        let app = launchApp()

        let aiEntry = app.buttons["打开 AI 创作工坊"]
        XCTAssertTrue(aiEntry.waitForExistence(timeout: 3))
        aiEntry.tap()

        let composerSurface = app.otherElements["ai-prompt-composer-surface"]
        XCTAssertTrue(composerSurface.waitForExistence(timeout: 3))

        guard waitForStableViewportDock(app: app, composerSurface: composerSurface) != nil else {
            XCTFail(
                "首次进入页面时 Composer 应直接停靠视口底部；"
                    + layoutDiagnostics(
                        app: app,
                        composerSurface: composerSurface,
                        keyboard: app.keyboards.firstMatch
                    )
            )
            return
        }
    }

    func testComposerCanStopSlowGeneration() {
        let app = launchApp(extraArguments: [
            "-developer.mockScenario", "slowSuccess"
        ])

        let aiEntry = app.buttons["打开 AI 创作工坊"]
        XCTAssertTrue(aiEntry.waitForExistence(timeout: 3))
        aiEntry.tap()

        let promptField = app.textViews["ai-prompt-composer"]
        XCTAssertTrue(promptField.waitForExistence(timeout: 3))
        promptField.tap()
        promptField.typeText("验证停止生成")

        let generateButton = app.buttons["开始生成"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 2))
        generateButton.tap()

        let stopButton = app.buttons["停止生成"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 2))

        let composerSurface = app.otherElements["ai-prompt-composer-surface"]
        XCTAssertTrue(composerSurface.waitForExistence(timeout: 2))
        guard waitForStableViewportDock(app: app, composerSurface: composerSurface) != nil else {
            XCTFail(
                "生成状态圆点运行时 Composer 未能稳定停靠；"
                    + layoutDiagnostics(
                        app: app,
                        composerSurface: composerSurface,
                        keyboard: app.keyboards.firstMatch
                    )
            )
            return
        }

        var generationPositions: [CGFloat] = []
        for _ in 0..<14 {
            generationPositions.append(composerSurface.frame.minY)
            Thread.sleep(forTimeInterval: 0.15)
        }
        let generationTravel = (generationPositions.max() ?? 0)
            - (generationPositions.min() ?? 0)
        XCTAssertLessThanOrEqual(
            generationTravel,
            4,
            "生成状态的无限脉冲动画不能传播到 Composer 布局：\(generationPositions)"
        )

        stopButton.tap()

        XCTAssertTrue(generateButton.waitForExistence(timeout: 3))
        XCTAssertTrue(generateButton.isHittable)
    }

    func testComposerStaysDockedWhileEditingExistingResult() {
        let app = launchApp(extraArguments: [
            "-developer.mockScenario", "fastSuccess"
        ])

        let aiEntry = app.buttons["打开 AI 创作工坊"]
        XCTAssertTrue(aiEntry.waitForExistence(timeout: 3))
        aiEntry.tap()

        let promptField = app.textViews["ai-prompt-composer"]
        XCTAssertTrue(promptField.waitForExistence(timeout: 3))
        promptField.tap()
        promptField.typeText("荷花")

        let generateButton = app.buttons["开始生成"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 2))
        generateButton.tap()
        XCTAssertTrue(app.staticTexts["AI 工艺建议"].waitForExistence(timeout: 8))

        let composerSurface = app.otherElements["ai-prompt-composer-surface"]
        XCTAssertTrue(composerSurface.waitForExistence(timeout: 2))
        let keyboardBeforeRefocus = app.keyboards.firstMatch
        guard waitForStableViewportDock(app: app, composerSurface: composerSurface) != nil else {
            XCTFail(
                "键盘隐藏后 Composer 未能稳定回到窗口底部；"
                    + layoutDiagnostics(
                        app: app,
                        composerSurface: composerSurface,
                        keyboard: keyboardBeforeRefocus
                    )
            )
            return
        }
        promptField.tap()
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 3))

        // XCUITest 输入时会短暂重建软键盘来注入按键，因此先等待一组真正
        // 可见且连续稳定的键盘/Composer 布局，再进行前后对比。
        guard let dockedPosition = waitForStableDockedPosition(
            app: app,
            composerSurface: composerSurface,
            keyboard: keyboard
        ) else {
            XCTFail("Composer 未能稳定停靠在可见键盘上方")
            return
        }

        promptField.typeText("继续")

        guard let positionAfterTyping = waitForStableDockedPosition(
            app: app,
            composerSurface: composerSurface,
            keyboard: keyboard
        ) else {
            XCTFail("追加输入后 Composer 未能恢复稳定停靠")
            return
        }

        var verticalPositions: [CGFloat] = []
        for _ in 0..<10 {
            verticalPositions.append(composerSurface.frame.minY)
            Thread.sleep(forTimeInterval: 0.20)
        }

        let verticalTravel = (verticalPositions.max() ?? 0) - (verticalPositions.min() ?? 0)
        XCTAssertLessThanOrEqual(
            verticalTravel,
            4,
            "Composer 不应在键盘与无键盘布局之间循环：\(verticalPositions)"
        )
        XCTAssertLessThanOrEqual(
            abs(positionAfterTyping - dockedPosition),
            4,
            "输入前后 Composer 应保持同一键盘停靠位置"
        )
        XCTAssertTrue(
            keyboardIsVisiblyDocked(
                appFrame: app.frame,
                composerFrame: composerSurface.frame,
                keyboardFrame: keyboard.frame,
                keyboardExists: keyboard.exists
            )
        )
    }

    func testComposerGrowsForMultipleLinesAndKeepsSendAction() {
        let app = launchApp()

        let aiEntry = app.buttons["打开 AI 创作工坊"]
        XCTAssertTrue(aiEntry.waitForExistence(timeout: 3))
        aiEntry.tap()

        let promptField = app.textViews["ai-prompt-composer"]
        XCTAssertTrue(promptField.waitForExistence(timeout: 3))
        let composerSurface = app.otherElements["ai-prompt-composer-surface"]
        XCTAssertTrue(composerSurface.waitForExistence(timeout: 2))
        let initialHeight = composerSurface.frame.height

        promptField.tap()
        promptField.typeText(
            "第一行灵感\n第二行构图\n第三行色彩\n第四行针法\n第五行材质\n第六行故事\n第七行细节\n第八行收束"
        )

        XCTAssertGreaterThan(composerSurface.frame.height, initialHeight)
        XCTAssertLessThanOrEqual(composerSurface.frame.height, 153)
        XCTAssertTrue(app.buttons["开始生成"].isHittable)
    }

    func testReduceMotionComposerRemainsUsable() {
        let app = launchApp(extraArguments: [
            "--force-reduce-motion"
        ])

        let aiEntry = app.buttons["打开 AI 创作工坊"]
        XCTAssertTrue(aiEntry.waitForExistence(timeout: 3))
        aiEntry.tap()

        let promptField = app.textViews["ai-prompt-composer"]
        XCTAssertTrue(promptField.waitForExistence(timeout: 3))
        promptField.tap()
        promptField.typeText("   ")
        XCTAssertTrue(app.buttons["开始语音输入"].exists)

        promptField.typeText("减弱动态效果\n也能正常输入")
        XCTAssertTrue(app.buttons["开始生成"].isHittable)
    }

    private func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)"] + extraArguments
        app.launch()
        return app
    }

    private func waitForStableDockedPosition(
        app: XCUIApplication,
        composerSurface: XCUIElement,
        keyboard: XCUIElement,
        timeout: TimeInterval = 5
    ) -> CGFloat? {
        let deadline = Date().addingTimeInterval(timeout)
        var previousPosition: CGFloat?
        var stableSampleCount = 0

        repeat {
            let composerFrame = composerSurface.frame
            let keyboardFrame = keyboard.frame
            let isDocked = keyboardIsVisiblyDocked(
                appFrame: app.frame,
                composerFrame: composerFrame,
                keyboardFrame: keyboardFrame,
                keyboardExists: keyboard.exists
            )

            if isDocked,
               let previousPosition,
               abs(composerFrame.minY - previousPosition) <= 2 {
                stableSampleCount += 1
            } else {
                stableSampleCount = isDocked ? 1 : 0
            }

            if stableSampleCount >= 3 {
                return composerFrame.minY
            }

            previousPosition = isDocked ? composerFrame.minY : nil
            Thread.sleep(forTimeInterval: 0.12)
        } while Date() < deadline

        return nil
    }

    /// `XCUIKeyboard.frame` 在 XCUITest 为注入文字而重建软键盘时，可能会
    /// 保留原高度却整体移到屏幕下方。只检查高度会把这个离屏快照误判成
    /// 已恢复稳定，因此还要确认键盘与应用窗口相交，并且 Composer 的底边
    /// 确实贴在键盘顶边附近。
    private func keyboardIsVisiblyDocked(
        appFrame: CGRect,
        composerFrame: CGRect,
        keyboardFrame: CGRect,
        keyboardExists: Bool
    ) -> Bool {
        let composerKeyboardGap = keyboardFrame.minY - composerFrame.maxY

        return keyboardExists
            && keyboardFrame.height > 100
            && keyboardFrame.intersects(appFrame)
            && composerKeyboardGap >= -2
            && composerKeyboardGap <= 60
    }

    /// 键盘隐藏时 Composer 必须由窗口底部定位，不能跟随结果图片高度进入
    /// ScrollView 内容流。等待连续稳定样本可过滤键盘退出动画本身。
    private func waitForStableViewportDock(
        app: XCUIApplication,
        composerSurface: XCUIElement,
        timeout: TimeInterval = 5
    ) -> CGFloat? {
        let deadline = Date().addingTimeInterval(timeout)
        var previousPosition: CGFloat?
        var stableSampleCount = 0
        viewportDockSamples = []

        repeat {
            let composerFrame = composerSurface.frame
            let bottomGap = app.frame.maxY - composerFrame.maxY
            let isDocked = bottomGap >= -2 && bottomGap <= 80
            viewportDockSamples.append(
                "y=\(composerFrame.minY.rounded()), gap=\(bottomGap.rounded())"
            )

            if isDocked,
               let previousPosition,
               abs(composerFrame.minY - previousPosition) <= 2 {
                stableSampleCount += 1
            } else {
                stableSampleCount = isDocked ? 1 : 0
            }

            if stableSampleCount >= 3 {
                return composerFrame.minY
            }

            previousPosition = isDocked ? composerFrame.minY : nil
            Thread.sleep(forTimeInterval: 0.12)
        } while Date() < deadline

        return nil
    }

    private func layoutDiagnostics(
        app: XCUIApplication,
        composerSurface: XCUIElement,
        keyboard: XCUIElement
    ) -> String {
        let generationScroll = app.scrollViews["ai-generation-scroll"]

        return [
            "app=\(app.frame)",
            "scroll=\(frameDescription(for: generationScroll))",
            "composer=\(frameDescription(for: composerSurface))",
            "keyboard=\(frameDescription(for: keyboard))",
            "samples=[\(viewportDockSamples.joined(separator: "; "))]"
        ].joined(separator: ", ")
    }

    private func frameDescription(for element: XCUIElement) -> String {
        guard element.exists else { return "missing" }
        return "\(element.frame)"
    }

}
