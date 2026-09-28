import AzooKeyUtils
import SwiftUI

struct MultiscriptGuideView: View {
    @State private var script = ScriptKanaConverter.Script.arabic
    @State private var source = "نيهۆن"
    @State private var practice = ""

    private var sample: String {
        switch script {
        case .arabic: "نيهۆن"
        case .persian: "نیهۆن"
        case .zhuyin: "ㄋㄧㄏㄛㄣ"
        }
    }

    // Separate text views prevent bidirectional Arabic text from reversing the
    // arrow and kana. Layout direction alone does not change Unicode bidi runs.
    private func phoneticExamples(_ examples: [(String, String)]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: 12) {
            ForEach(examples.indices, id: \.self) { index in
                HStack(spacing: 6) {
                    Text(examples[index].0)
                    Text("→")
                    Text(examples[index].1)
                }
                .font(.title3)
                .accessibilityElement(children: .combine)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    var body: some View {
        Form {
            Section {
                Text("使い慣れた文字で、日本語を。")
                    .font(.title2.bold())
                Text("日本語の読みを1音ずつ入力すると、かなと漢字の候補が出ます。Pismo独自の音の対応を使います。文章の翻訳機能ではありません。")
            }
            Section("かなへの変換を試す") {
                Picker("入力文字", selection: $script) {
                    Text("アラビア文字").tag(ScriptKanaConverter.Script.arabic)
                    Text("ペルシャ文字").tag(ScriptKanaConverter.Script.persian)
                    Text("台湾華語・注音").tag(ScriptKanaConverter.Script.zhuyin)
                }
                .accessibilityIdentifier("scriptPicker")
                TextField("変換元の文字", text: $source)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("scriptSource")
                LabeledContent("ひらがな") {
                    Text(ScriptKanaConverter(script: script).convert(source))
                        .font(.title2)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("scriptResult")
                }
                Button("「にほん」の入力例を表示") { source = sample }
            }
            Section("5つの母音") {
                phoneticExamples(script == .zhuyin
                    ? [("ㄚ", "あ"), ("ㄧ", "い"), ("ㄨ", "う"), ("ㄝ", "え"), ("ㄛ", "お")]
                    : [("ا", "あ"), ("ي / ی", "い"), ("و", "う"), ("ې", "え"), ("ۆ", "お")])
                if script != .zhuyin {
                    Text("「え」「お」を区別するため、拡張アラビア文字の ې・ۆ を使います。子音のあとにも母音を入力してください。ك と ک、ي と ی はどちらも使えます。")
                }
            }
            Section("子音と組み合わせる") {
                phoneticExamples(script == .zhuyin
                    ? [("ㄎㄚ", "か"), ("ㄙㄨ", "す"), ("ㄎㄧㄚ", "きゃ"), ("ㄋㄧ", "に"), ("ㄣ", "ん"), ("ㄎㄎㄚ", "っか")]
                    : [("كا / کا", "か"), ("سو", "す"), ("كيا / کیا", "きゃ"), ("ني / نی", "に"), ("ن", "ん"), ("ككا / ککا", "っか")])
                Text("母音キーを上にフリックすると小さい「ぁ・ぃ・ぅ・ぇ・ぉ」を入力できます。ف / ㄈ の上フリックには、ヴ音用の ڤ / ㄪ があります。")
                Text("「っ」「ー」は専用キーでも入力できます。「い・あ」を別々の音にする場合は間に ' を入れます。注音の声調符号は日本語に出力しません。")
            }
            Section("キーボードを使う") {
                Text("iOSの「設定」→「一般」→「キーボード」→「キーボード」→「新しいキーボードを追加」でPismoを追加します。")
                Text("Pismoのキーボード上部にある文字ボタンから配列を選べます。フルアクセスは基本の日本語入力に必要ありません。設定の共有や任意の追加機能で使います。")
                TextField("ここでキーボードを試す", text: $practice, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityIdentifier("keyboardPractice")
                Text("地球儀でPismoに切り替え、「にほん」を入力して「日本」の候補を選んでください。パスワード欄などではiOS標準キーボードに切り替わります。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("文字で日本語を入力")
        .onChange(of: script) { _, _ in source = sample }
    }
}
