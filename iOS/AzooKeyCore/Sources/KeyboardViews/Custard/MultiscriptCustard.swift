import CustardKit

public extension Custard {
    static let arabicJapanese = phoneticKeyboard(
        identifier: "arabic_japanese", name: "アラビア文字 → 日本語",
        rows: [
            ["ا", "ي", "و", "ې", "ۆ", "پ", "گ", "چ", "ー", "ん"],
            ["ق", "ك", "س", "ز", "ت", "د", "ن", "ه", "ب", "ف"],
            ["ش", "ج", "م", "ر", "ل", "ح", "خ", "غ", "ص", "ض"],
            ["ث", "ذ", "ط", "'", "っ", "ゃ", "ゅ", "ょ", "、", "。"]
        ])
    static let persianJapanese = phoneticKeyboard(
        identifier: "persian_japanese", name: "ペルシャ文字 → 日本語",
        rows: [
            ["ا", "ی", "و", "ې", "ۆ", "پ", "گ", "چ", "ー", "ん"],
            ["ق", "ک", "س", "ز", "ت", "د", "ن", "ه", "ب", "ف"],
            ["ش", "ج", "م", "ر", "ل", "ح", "خ", "غ", "ژ", "ض"],
            ["ث", "ذ", "ط", "'", "っ", "ゃ", "ゅ", "ょ", "،", "۔"]
        ])
    static let zhuyinJapanese = phoneticKeyboard(
        identifier: "zhuyin_japanese", name: "台湾華語・注音 → 日本語",
        rows: [
            ["ㄅ", "ㄉ", "ㄓ", "ㄚ", "ㄞ", "ㄢ", "ㄦ", "'", "ー", "っ"],
            ["ㄆ", "ㄊ", "ㄍ", "ㄐ", "ㄔ", "ㄗ", "ㄧ", "ㄛ", "ㄟ", "ㄣ"],
            ["ㄇ", "ㄋ", "ㄎ", "ㄑ", "ㄕ", "ㄘ", "ㄨ", "ㄜ", "ㄠ", "ㄤ"],
            ["ㄈ", "ㄌ", "ㄏ", "ㄒ", "ㄖ", "ㄙ", "ㄩ", "ㄝ", "ㄡ", "ㄥ"]
        ])

    private static func phoneticKeyboard(identifier: String, name: String, rows: [[String]]) -> Custard {
        var keys: [CustardKeyPositionSpecifier: CustardInterfaceKey] = [:]
        for (y, row) in rows.enumerated() {
            for (x, text) in row.enumerated() {
                let alternate: String? = [
                    "ا": "ぁ", "ي": "ぃ", "ی": "ぃ", "و": "ぅ", "ې": "ぇ", "ۆ": "ぉ",
                    "ㄚ": "ぁ", "ㄧ": "ぃ", "ㄨ": "ぅ", "ㄝ": "ぇ", "ㄛ": "ぉ",
                    "ف": "ڤ", "ㄈ": "ㄪ"
                ][text]
                let variations: [CustardInterfaceVariation] = alternate.map {
                    [.init(type: .flickVariation(.top), key: .init(
                        design: .init(label: .text($0)), press_actions: [.input($0)], longpress_actions: .none))]
                } ?? []
                keys[.gridFit(.init(x: x, y: y))] = .custom(.init(
                    design: .init(label: .text(text), color: .normal),
                    press_actions: [.input(text)], longpress_actions: .none, variations: variations))
            }
        }
        keys[.gridFit(.init(x: 0, y: 4))] = .custom(.init(
            design: .init(label: .text("123"), color: .special),
            press_actions: [.moveTab(.system(.flick_numbersymbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []), variations: []))
        keys[.gridFit(.init(x: 1, y: 4))] = .system(.changeKeyboard)
        keys[.gridFit(.init(x: 2, y: 4, width: 4, height: 1))] = .custom(.flickSpace())
        keys[.gridFit(.init(x: 6, y: 4, width: 2, height: 1))] = .custom(.flickDelete())
        keys[.gridFit(.init(x: 8, y: 4, width: 2, height: 1))] = .system(.enter)
        return Custard(identifier: identifier, language: .ja_JP, input_style: .direct,
                       metadata: .init(custard_version: .v1_2, display_name: name),
                       interface: .init(keyStyle: .pcStyle,
                                        keyLayout: .gridFit(.init(rowCount: 10, columnCount: 5)), keys: keys))
    }
}
