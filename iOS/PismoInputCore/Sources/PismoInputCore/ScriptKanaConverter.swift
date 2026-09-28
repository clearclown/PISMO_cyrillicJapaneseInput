import Foundation

/// Pismo's phonetic input convention. This is not a translator or a standard
/// romanization of Arabic, Persian, or Mandarin words.
public struct ScriptKanaConverter: Sendable {
    public enum Script: String, CaseIterable, Sendable {
        case arabic = "arabic_japanese"
        case persian = "persian_japanese"
        case zhuyin = "zhuyin_japanese"
    }

    public let script: Script
    private let mapping: [String: String]
    private let consonants: Set<String>
    private let maxLength: Int

    public init(script: Script) {
        self.script = script
        let tables = Self.tables[script]!
        mapping = tables.mapping
        consonants = tables.consonants
        maxLength = mapping.keys.map { $0.unicodeScalars.count }.max() ?? 1
    }

    private static let tables: [Script: (mapping: [String: String], consonants: Set<String>)] =
        Dictionary(uniqueKeysWithValues: Script.allCases.map { ($0, makeMapping($0)) })

    public func accepts(_ text: String) -> Bool {
        !text.isEmpty && text.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 0x0600...0x06FF, 0x0750...0x077F, 0x08A0...0x08FF,
                 0xFB50...0xFDFF, 0xFE70...0xFEFF:
                return script != .zhuyin
            case 0x3100...0x312F, 0x31A0...0x31BF, 0x02C7, 0x02CA, 0x02CB, 0x02D9:
                return script == .zhuyin
            case 0x0027, 0x2019, 0x200C, 0x200D: return true
            default: return false
            }
        }
    }

    public func convert(_ source: String) -> String {
        let units = source.precomposedStringWithCompatibilityMapping.unicodeScalars.map(String.init)
        var result = ""
        var index = 0
        while index < units.count {
            let current = units[index]
            // Explicit syllable boundaries and tone marks consume no Japanese text.
            if ["'", "’", "‌", "‍", "ˇ", "ˊ", "ˋ", "˙", "ـ", "ْ"].contains(current) {
                index += 1
                continue
            }
            if index + 1 < units.count, current == units[index + 1], consonants.contains(current) {
                result += current == "ن" ? "ん" : "っ"
                index += current == "ن" ? 2 : 1
                continue
            }
            var matched = false
            for count in stride(from: min(maxLength, units.count - index), through: 1, by: -1) {
                let key = units[index..<(index + count)].joined()
                if let kana = mapping[key] {
                    result += kana
                    index += count
                    matched = true
                    break
                }
            }
            if !matched {
                result += current
                index += 1
            }
        }
        return result
    }

    private static func makeMapping(_ script: Script) -> (mapping: [String: String], consonants: Set<String>) {
        var map: [String: String] = [:]
        let vowels: [[String]] = script == .zhuyin
            ? [["ㄚ"], ["ㄧ"], ["ㄨ"], ["ㄝ", "ㄜ"], ["ㄛ"]]
            : [["ا", "آ", "أ", "َ"], ["ي", "ی", "إ", "ِ"], ["و", "ُ"], ["ې", "ێ"], ["ۆ"]]
        for (aliases, kana) in zip(vowels, ["あ", "い", "う", "え", "お"]) {
            for alias in aliases { map[alias] = kana }
        }
        let rows: [(String, [String], String)] = script == .zhuyin ? [
            ("ㄎ", ["か", "き", "く", "け", "こ"], "き"),
            ("ㄍ", ["が", "ぎ", "ぐ", "げ", "ご"], "ぎ"),
            ("ㄙ", ["さ", "し", "す", "せ", "そ"], "し"),
            ("ㄗ", ["ざ", "じ", "ず", "ぜ", "ぞ"], "じ"),
            ("ㄊ", ["た", "ち", "つ", "て", "と"], "ち"),
            ("ㄉ", ["だ", "ぢ", "づ", "で", "ど"], "ぢ"),
            ("ㄋ", ["な", "に", "ぬ", "ね", "の"], "に"),
            ("ㄏ", ["は", "ひ", "ふ", "へ", "ほ"], "ひ"),
            ("ㄅ", ["ば", "び", "ぶ", "べ", "ぼ"], "び"),
            ("ㄆ", ["ぱ", "ぴ", "ぷ", "ぺ", "ぽ"], "ぴ"),
            ("ㄇ", ["ま", "み", "む", "め", "も"], "み"),
            ("ㄌㄖ", ["ら", "り", "る", "れ", "ろ"], "り"),
            ("ㄕㄒ", ["しゃ", "し", "しゅ", "しぇ", "しょ"], "し"),
            ("ㄓㄐ", ["じゃ", "じ", "じゅ", "じぇ", "じょ"], "じ"),
            ("ㄔㄑ", ["ちゃ", "ち", "ちゅ", "ちぇ", "ちょ"], "ち"),
            ("ㄘ", ["つぁ", "つぃ", "つ", "つぇ", "つぉ"], "つ"),
            ("ㄈ", ["ふぁ", "ふぃ", "ふ", "ふぇ", "ふぉ"], "ふ"),
            ("ㄪ", ["ゔぁ", "ゔぃ", "ゔ", "ゔぇ", "ゔぉ"], "ゔ")
        ] : [
            ("كکق", ["か", "き", "く", "け", "こ"], "き"),
            ("گغ", ["が", "ぎ", "ぐ", "げ", "ご"], "ぎ"),
            ("سصث", ["さ", "し", "す", "せ", "そ"], "し"),
            ("زذظ", ["ざ", "じ", "ず", "ぜ", "ぞ"], "じ"),
            ("تط", ["た", "ち", "つ", "て", "と"], "ち"),
            ("دض", ["だ", "ぢ", "づ", "で", "ど"], "ぢ"),
            ("ن", ["な", "に", "ぬ", "ね", "の"], "に"),
            ("هحخھ", ["は", "ひ", "ふ", "へ", "ほ"], "ひ"),
            ("ب", ["ば", "び", "ぶ", "べ", "ぼ"], "び"),
            ("پ", ["ぱ", "ぴ", "ぷ", "ぺ", "ぽ"], "ぴ"),
            ("م", ["ま", "み", "む", "め", "も"], "み"),
            ("رل", ["ら", "り", "る", "れ", "ろ"], "り"),
            ("ش", ["しゃ", "し", "しゅ", "しぇ", "しょ"], "し"),
            ("جژ", ["じゃ", "じ", "じゅ", "じぇ", "じょ"], "じ"),
            ("چ", ["ちゃ", "ち", "ちゅ", "ちぇ", "ちょ"], "ち"),
            ("ف", ["ふぁ", "ふぃ", "ふ", "ふぇ", "ふぉ"], "ふ"),
            ("ڤ", ["ゔぁ", "ゔぃ", "ゔ", "ゔぇ", "ゔぉ"], "ゔ")
        ]
        var consonants = Set<String>()
        for (aliases, kanaRow, palatalBase) in rows {
            for consonant in aliases.map(String.init) {
                consonants.insert(consonant)
                for (vowelAliases, kana) in zip(vowels, kanaRow) {
                    for vowel in vowelAliases { map[consonant + vowel] = kana }
                }
                for medial in vowels[1] {
                    for (vowelIndex, smallKana) in [(0, "ゃ"), (2, "ゅ"), (4, "ょ")] {
                        for vowel in vowels[vowelIndex] {
                            map[consonant + medial + vowel] = palatalBase + smallKana
                        }
                    }
                }
                if script == .zhuyin {
                    // Compound finals occupy one Zhuyin key. Combine them with
                    // the preceding consonant just like their vowel sequence.
                    for (final, vowelIndex, suffix) in [
                        ("ㄞ", 0, "い"), ("ㄟ", 3, "い"), ("ㄠ", 0, "う"), ("ㄡ", 4, "う"),
                        ("ㄢ", 0, "ん"), ("ㄣ", 3, "ん"), ("ㄤ", 0, "ん"), ("ㄥ", 3, "ん")
                    ] {
                        map[consonant + final] = kanaRow[vowelIndex] + suffix
                        if vowelIndex == 0 {
                            map[consonant + "ㄧ" + final] = palatalBase + "ゃ" + suffix
                        }
                    }
                    map[consonant + "ㄩ"] = palatalBase + "ゅ"
                }
                // Arabic shadda explicitly doubles a consonant.
                if script != .zhuyin {
                    for (vowelAliases, kana) in zip(vowels, kanaRow) {
                        for vowel in vowelAliases {
                            map[consonant + "ّ" + vowel] = "っ" + kana
                            map[consonant + vowel + "ّ"] = "っ" + kana
                        }
                    }
                }
            }
        }
        for medial in vowels[1] {
            for (vowelIndex, kana) in [(0, "や"), (2, "ゆ"), (4, "よ")] {
                for vowel in vowels[vowelIndex] { map[medial + vowel] = kana }
            }
        }
        for medial in vowels[2] {
            for vowel in vowels[0] { map[medial + vowel] = "わ" }
            for vowel in vowels[4] { map[medial + vowel] = "を" }
        }
        if script == .zhuyin {
            map.merge(["ㄣ": "ん", "ㄢ": "あん", "ㄤ": "あん", "ㄥ": "ん",
                       "ㄞ": "あい", "ㄟ": "えい", "ㄠ": "あう", "ㄡ": "おう",
                       "ㄦ": "る", "ㄩ": "ゆ"], uniquingKeysWith: { _, new in new })
        } else {
            map["ن"] = "ん"
            map["ں"] = "ん"
            map["،"] = "、"
            map["۔"] = "。"
            map["؟"] = "？"
        }
        return (map, consonants)
    }
}

/// A bounded composition segment. Operations only replace text owned by this
/// segment, and are invalidated when a host/cursor edit changes its anchor.
public struct ScriptComposition: Sendable {
    public struct Edit: Equatable, Sendable {
        public let deleteCount: Int
        public let text: String
    }
    public private(set) var source = ""
    private var rendered = ""
    private var anchor: String?
    private var script: ScriptKanaConverter.Script?

    public init() {}

    public mutating func reset() { self = Self() }

    public mutating func append(_ text: String, beforeCursor: String, script: ScriptKanaConverter.Script) -> Edit {
        if self.script != script || anchor.map({ $0 + rendered != beforeCursor }) ?? true || source.count > 256 {
            reset()
            self.script = script
            anchor = beforeCursor
        }
        source += text
        let converted = ScriptKanaConverter(script: script).convert(source)
        let commonCount = zip(rendered, converted).prefix(while: { $0 == $1 }).count
        let edit = Edit(deleteCount: rendered.count - commonCount, text: String(converted.dropFirst(commonCount)))
        rendered = converted
        return edit
    }
}
