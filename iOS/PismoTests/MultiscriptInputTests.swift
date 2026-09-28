import AzooKeyUtils
import KanaKanjiConverterModule
import XCTest

@MainActor final class MultiscriptInputTests: XCTestCase {
    func testEveryScriptReachesJapaneseComposition() {
        for (identifier, source) in [("arabic_japanese", "نيهۆن"), ("persian_japanese", "نیهۆن"), ("zhuyin_japanese", "ㄋㄧㄏㄛㄣ")] {
            let manager = InputManager()
            manager.setInputProfile(for: identifier)
            for scalar in source.unicodeScalars {
                manager.input(text: String(scalar), requireSetResult: false, inputStyle: .direct)
            }
            XCTAssertEqual(manager.getComposingText().convertTarget, "にほん", identifier)
        }
    }

    func testCyrillicGeminationDoesNotRecurse() {
        let manager = InputManager()
        manager.setInputProfile(for: "cyrillic_standard")
        manager.input(text: "иттэ", requireSetResult: false, inputStyle: .direct)
        XCTAssertEqual(manager.getComposingText().convertTarget, "いって")
    }

    func testBackspaceDoesNotRestoreDeletedSource() {
        let manager = InputManager()
        manager.setInputProfile(for: "arabic_japanese")
        manager.input(text: "كا", requireSetResult: false, inputStyle: .direct)
        manager.deleteBackward(convertTargetCount: 1, requireSetResult: false)
        manager.input(text: "ا", requireSetResult: false, inputStyle: .direct)
        XCTAssertEqual(manager.getComposingText().convertTarget, "あ")
    }

    func testLayoutSwitchDoesNotReusePendingConsonant() {
        let manager = InputManager()
        manager.setInputProfile(for: "arabic_japanese")
        manager.input(text: "ك", requireSetResult: false, inputStyle: .direct)
        manager.setInputProfile(for: "zhuyin_japanese")
        manager.input(text: "ㄚ", requireSetResult: false, inputStyle: .direct)
        XCTAssertEqual(manager.getComposingText().convertTarget, "كあ")
    }

    func testConvertedReadingsHaveKanjiCandidates() {
        let dictionary = Bundle(for: type(of: self)).bundleURL.appendingPathComponent("Dictionary")
        let converter = KanaKanjiConverter(dicdataStore: DicdataStore(dictionaryURL: dictionary))
        let options = ConvertRequestOptions(
            N_best: 10, requireJapanesePrediction: true, requireEnglishPrediction: false,
            keyboardLanguage: .ja_JP, learningType: .nothing,
            memoryDirectoryURL: FileManager.default.temporaryDirectory,
            sharedContainerURL: FileManager.default.temporaryDirectory,
            textReplacer: .empty,
            specialCandidateProviders: [], metadata: .init(versionString: "Pismo Tests"))
        for script in ScriptKanaConverter.Script.allCases {
            let source = script == .zhuyin ? "ㄋㄧㄏㄛㄣ" : "نیهۆن"
            var composing = ComposingText()
            composing.insertAtCursorPosition(ScriptKanaConverter(script: script).convert(source), inputStyle: .direct)
            let candidates = converter.requestCandidates(composing, options: options).mainResults
            XCTAssertTrue(candidates.contains { $0.text == "日本" }, "\(script): \(candidates.map(\.text))")
            converter.stopComposition()
        }
    }
}
