import XCTest
@testable import PismoInputCore

final class ScriptKanaConverterTests: XCTestCase {
    func testArabicJapaneseWords() {
        let converter = ScriptKanaConverter(script: .arabic)
        for (source, kana) in ["نيهۆن": "にほん", "ساكورا": "さくら", "كاتاكانا": "かたかな", "سوشي": "すし", "كۆن'نيچيها": "こんにちは"] {
            XCTAssertEqual(converter.convert(source), kana, source)
        }
    }

    func testPersianFormsAndCompatibilityGlyphs() {
        let converter = ScriptKanaConverter(script: .persian)
        XCTAssertEqual(converter.convert("نیهۆن"), "にほん")
        XCTAssertEqual(converter.convert("کاکی"), "かき")
        XCTAssertEqual(converter.convert("كاكي"), "かき")
        XCTAssertEqual(converter.convert("ﻛﺎ"), "か")
        XCTAssertEqual(converter.convert("گاککۆو"), "がっこう")
    }

    func testShortVowelsAndShadda() {
        let converter = ScriptKanaConverter(script: .arabic)
        XCTAssertEqual(converter.convert("كَكِكُ"), "かきく")
        XCTAssertEqual(converter.convert("كَّا"), "っかあ")
        XCTAssertEqual(converter.convert("كَّ"), "っか")
    }

    func testZhuyinJapaneseWords() {
        let converter = ScriptKanaConverter(script: .zhuyin)
        for (source, kana) in ["ㄋㄧㄏㄛㄣ": "にほん", "ㄙㄚㄎㄨㄌㄚ": "さくら", "ㄎㄚㄊㄚㄎㄚㄋㄚ": "かたかな", "ㄙㄨㄒㄧ": "すし", "ㄊㄛㄨㄎㄧㄛㄨ": "とうきょう"] {
            XCTAssertEqual(converter.convert(source), kana, source)
        }
    }

    func testPalatalizedSoundsAndForeignSounds() {
        XCTAssertEqual(ScriptKanaConverter(script: .arabic).convert("كياشوجياچيوفا"), "きゃしゅじゃちゅふぁ")
        XCTAssertEqual(ScriptKanaConverter(script: .zhuyin).convert("ㄎㄧㄚㄒㄨㄐㄚㄑㄨㄈㄚ"), "きゃしゅじゃちゅふぁ")
    }

    func testZhuyinCompoundFinals() {
        let converter = ScriptKanaConverter(script: .zhuyin)
        for (source, expected) in ["ㄊㄞ": "たい", "ㄙㄟ": "せい", "ㄊㄡ": "とう",
                                   "ㄅㄢ": "ばん", "ㄏㄣ": "へん", "ㄋㄩ": "にゅ",
                                   "ㄎㄧㄠ": "きゃう", "ㄐㄩ": "じゅ"] {
            XCTAssertEqual(converter.convert(source), expected, source)
        }
    }

    func testVoicedForeignSoundsAndParticleWo() {
        XCTAssertEqual(ScriptKanaConverter(script: .arabic).convert("ڤو وۆ"), "ゔ を")
        XCTAssertEqual(ScriptKanaConverter(script: .zhuyin).convert("ㄪㄨ ㄨㄛ"), "ゔ を")
    }

    func testVowelsNasalAndGemination() {
        XCTAssertEqual(ScriptKanaConverter(script: .arabic).convert("ا ي و ې ۆ ن ككا"), "あ い う え お ん っか")
        XCTAssertEqual(ScriptKanaConverter(script: .zhuyin).convert("ㄚㄧㄨㄝㄛㄣㄎㄎㄚ"), "あゆえおんっか")
        XCTAssertEqual(ScriptKanaConverter(script: .zhuyin).convert("ㄚ'ㄧ'ㄨ'ㄝ'ㄛ"), "あいうえお")
    }

    func testPunctuationUnknownTextAndToneBoundaries() {
        XCTAssertEqual(ScriptKanaConverter(script: .persian).convert("کا، ۱۲۳🙂۔"), "か、 ۱۲۳🙂。")
        XCTAssertEqual(ScriptKanaConverter(script: .zhuyin).convert("ㄧˊㄚ"), "いあ")
        XCTAssertEqual(ScriptKanaConverter(script: .arabic).convert("ي'ا"), "いあ")
    }

    func testStreamingAgreesWithWholeInputAtEveryScalar() {
        let words: [(ScriptKanaConverter.Script, String)] = [
            (.arabic, "كۆن'نيچيها"), (.arabic, "كَكِكُ"), (.arabic, "كَّ"),
            (.persian, "گاککۆو"), (.zhuyin, "ㄊㄛㄨㄎㄧㄛㄨ"), (.zhuyin, "ㄊㄞㄅㄢㄋㄩㄎㄧㄠ")
        ]
        for (script, word) in words {
            var session = ScriptComposition()
            var buffer = "前文"
            var source = ""
            for scalar in word.unicodeScalars {
                let input = String(scalar)
                source += input
                let edit = session.append(input, beforeCursor: buffer, script: script)
                XCTAssertLessThanOrEqual(edit.deleteCount, buffer.count - 2)
                buffer = String(buffer.dropLast(edit.deleteCount)) + edit.text
                XCTAssertEqual(buffer, "前文" + ScriptKanaConverter(script: script).convert(source))
            }
        }
    }

    func testCursorHostEditsNeverDeleteUnownedText() {
        var session = ScriptComposition()
        _ = session.append("ك", beforeCursor: "", script: .arabic)
        let edit = session.append("ا", beforeCursor: "別の文章", script: .arabic)
        XCTAssertEqual(edit, .init(deleteCount: 0, text: "あ"))
    }

    func testResetAndScriptSwitchDoNotReuseConsonants() {
        var session = ScriptComposition()
        _ = session.append("ك", beforeCursor: "", script: .arabic)
        session.reset()
        XCTAssertEqual(session.append("ا", beforeCursor: "ك", script: .arabic), .init(deleteCount: 0, text: "あ"))
        XCTAssertEqual(session.append("ㄧ", beforeCursor: "كあ", script: .zhuyin), .init(deleteCount: 0, text: "い"))
    }

    func testCompositionIsBounded() {
        var session = ScriptComposition()
        var buffer = ""
        for _ in 0..<600 {
            let edit = session.append("ا", beforeCursor: buffer, script: .arabic)
            buffer = String(buffer.dropLast(edit.deleteCount)) + edit.text
        }
        XCTAssertEqual(buffer, String(repeating: "あ", count: 600))
        XCTAssertLessThanOrEqual(session.source.count, 257)
    }

    func testScriptDetectionDoesNotCaptureOrdinaryLatinInput() {
        XCTAssertTrue(ScriptKanaConverter(script: .arabic).accepts("كِ"))
        XCTAssertTrue(ScriptKanaConverter(script: .persian).accepts("کی"))
        XCTAssertTrue(ScriptKanaConverter(script: .zhuyin).accepts("ㄋㄧ"))
        for script in ScriptKanaConverter.Script.allCases {
            XCTAssertFalse(ScriptKanaConverter(script: script).accepts("abc"))
            XCTAssertFalse(ScriptKanaConverter(script: script).accepts(""))
            XCTAssertFalse(ScriptKanaConverter(script: script).accepts("\n"))
        }
    }
}
