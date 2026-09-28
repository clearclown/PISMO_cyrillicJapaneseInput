import XCTest
import UIKit

final class PismoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor func testAllScriptGuidesShowJapaneseOutput() {
        let app = XCUIApplication()
        app.launchArguments = ["--pismo-ui-testing", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        let settings = app.buttons["設定"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 20))
        settings.tap()
        app.buttons["アラビア文字・ペルシャ文字・注音の使い方"].tap()
        let result = app.staticTexts["scriptResult"]
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        XCTAssertTrue(result.label.hasSuffix("にほん"), result.label)
        saveScreenshot("Arabic guide")
        for (label, source, title) in [
            ("ペルシャ文字", "نیهۆن", "Persian guide"),
            ("台湾華語・注音", "ㄋㄧㄏㄛㄣ", "Zhuyin guide")
        ] {
            app.buttons["scriptPicker"].tap()
            app.buttons[label].tap()
            XCTAssertEqual(app.textFields["scriptSource"].value as? String, source)
            XCTAssertTrue(result.label.hasSuffix("にほん"), result.label)
            saveScreenshot(title)
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            defer { XCUIDevice.shared.orientation = .portrait }
            XCTAssertTrue(result.waitForExistence(timeout: 5))
            XCTAssertTrue(result.label.hasSuffix("にほん"))
            saveScreenshot("iPad landscape guide")
        }
    }

    @MainActor private func saveScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
