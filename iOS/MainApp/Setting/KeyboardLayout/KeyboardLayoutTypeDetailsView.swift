//
//  KeyboardLayoutTypeDetailsView.swift
//  MainApp
//
//  Created by ensan on 2020/12/30.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import Foundation
import SwiftUI

struct KeyboardLayoutTypeDetailsView: View {
    @AppStorage(UseStandardNumpad.key) private var useStandardNumpad = UseStandardNumpad.defaultValue

    var body: some View {
        Form {
            Section("キーボードの種類") {
                LanguageLayoutSettingView(.japaneseKeyboardLayout, language: .japanese).padding(.vertical)
            }
            Section("使い方ガイド") {
                NavigationLink("アラビア文字・ペルシャ文字・注音の入力") {
                    MultiscriptGuideView()
                }
                NavigationLink("キリル文字の入力例") {
                    Form {
                        Section("母音と子音") {
                            Text("а → あ、и → い、у → う、э → え、о → お")
                            Text("ка → か、ки → き、ку → く、кэ → け、ко → こ")
                            Text("кя → きゃ、иттэ → いって")
                        }
                        Section("配列ごとの違い") {
                            Text("キーボードの設定から使用する言語を選んでください。言語によって文字の配置と音の対応が異なります。")
                        }
                    }.navigationTitle("キリル文字の入力")
                }
                Text("入力例と、文字から日本語の読みへの変換方法を確認できます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("数字入力の方法") {
                Picker("数字入力の方法", selection: $useStandardNumpad) {
                    Text("標準式").tag(true)
                    Text("フリック式").tag(false)
                }
                .pickerStyle(.segmented)
                Text("標準式は一般的なiOSの数字・記号キーボードです。フリック式はフリック入力で数字を入力します。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }.navigationBarTitle(Text("キーボードの設定"), displayMode: .inline)
    }
}
