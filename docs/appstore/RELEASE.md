# Pismo 2.1 提出手順

対象はiPhone・iPad版（iOS / iPadOS 17.6以降）の担当者です。まず「ビルドする」までを実行し、提出直前に残りの項目を確認してください。ソースをビルドできることと、Appleの審査を通過することは別です。

## ビルドする

Xcode 26以降を使います。Appleは2026年4月28日以降の提出にiOS 26 SDK以降を要求しています。[Appleの提出要件](https://developer.apple.com/news/upcoming-requirements/?id=04282026a)

```sh
python3 scripts/prepare_ios_resources.py
swift test --package-path iOS/PismoInputCore
python3 scripts/validate_ios_release.py
xcodebuild -project iOS/Pismo.xcodeproj -scheme MainApp \
  -destination 'generic/platform=iOS' -configuration Release \
  -archivePath build/Pismo-2.1.xcarchive archive
```

`prepare_ios_resources.py`はZenzaiの2モデルと絵文字辞書を取得します。モデルのリビジョンとSHA-256は固定済みです。生成物はGit管理から除外してあります。通常のかな漢字辞書はリポジトリに同梱しています。

署名には、PismoのApp IDとApp Groupを利用できるApple Developerチームが必要です。プロジェクトの既存のBundle IDは`com.pismo.Pismo`、拡張は`com.pismo.Pismo.keyboard`、App Groupは`group.com.pismo.keyboard`です。別のIDに変更する場合は、entitlementsとSharedStoreの定数も一緒に更新します。チームを推測して置き換えないでください。

ローカルの[検証記録](VALIDATION.md)も確認してください。署名付きアーカイブは`build/Pismo-2.1.xcarchive`に保存します。XcodeのSettings → Accountsに公開用のApple Developerアカウントを追加し、配布証明書を利用できる状態にしてから、次のコマンドでIPAを書き出せます。

```sh
xcodebuild -exportArchive -archivePath build/Pismo-2.1.xcarchive \
  -exportOptionsPlist iOS/ExportOptions-AppStore.plist \
  -exportPath build/AppStore-2.1 -allowProvisioningUpdates
```

このExportOptionsはローカルへの書き出し用です。チームIDは本体・拡張と同じ既存の`Q9DB95D8L9`を指定しています。

配布用の署名後、Xcode Organizerから「Validate App」を実行し、その後「Distribute App」→「App Store Connect」へ進みます。アップロード後のビルドをTestFlightで検証してから審査に提出してください。

## 新しい3配列を確認する

Pismo内の「設定」→「キーボードの種類」から配列を選びます。キーボード上部の文字ボタンからも切り替えられます。後者はフルアクセスを許可しない場合にも使います。

| 配列 | 入力 | かな | 漢字候補 |
| --- | --- | --- | --- |
| アラビア文字 | نيهۆن | にほん | 日本 |
| ペルシャ文字 | نیهۆن | にほん | 日本 |
| 台湾華語・注音 | ㄋㄧㄏㄛㄣ | にほん | 日本 |

独自の音の対応を使います。アラビア語・ペルシャ語・台湾華語の文章を翻訳する機能ではありません。アラビア系配列の`ې`は「え」、`ۆ`は「お」です。注音の`ㄝ`は「え」、`ㄛ`は「お」です。

- iPhoneとiPadで、各配列から「にほん」を入力し、「日本」を確定する。
- 「きゃ」、促音、「ん」、長音、句読点、数字、削除、カーソル移動、候補の途中確定を試す。
- 機内モード・フルアクセスOFFで基本入力と配列切り替えを確認する。
- 地球儀ボタンから次のキーボードへ切り替えられることを確認する。
- キリル文字の既存配列、ライト／ダーク表示、縦／横画面でも入力する。
- ZenzaiのON/OFF、低／中／高を実機で確認する。拡張のメモリ制限による終了がないか確認する。

これは実機受け入れチェックです。シミュレータの検証結果とは分けて記録してください。

## 公開URLとプライバシーを確定する

2026年9月29日、既存のVercelサイトは利用上限超過で停止していました。既存のGitHub Pagesに[日本語ポリシー](https://clearclown.github.io/PISMO_cyrillicJapaneseInput/privacy_ja.html)、[英語ポリシー](https://clearclown.github.io/PISMO_cyrillicJapaneseInput/privacy.html)、[サポート](https://clearclown.github.io/PISMO_cyrillicJapaneseInput/support.html)を公開しました。App Store Connectには到達確認後のURLを登録します。アプリ内にも通信なしで読めるポリシーがあります。

通常入力は端末内で処理しますが、既存の誤変換レポート・単語提案には任意の送信機能があります。「データ収集なし」とは申告しないでください。現在のPrivacyInfo.xcprivacyでは、任意のユーザコンテンツ、ニックネーム、診断情報の収集を申告しています。App Store Connectでも、収集目的、本人との関連、任意送信であることを実際の運用に合わせて回答します。

2026年9月29日、既存Google Formsをご自身で管理していることをアカウント所有者に確認済みです。保存期間や削除対応は、このポリシーに沿って運用してください。フォームには入力内容、任意の文脈・ニックネーム、診断情報が含まれます。プライバシーポリシーの連絡先は既存アプリの連絡先を引き継いでいます。

## App Store Connectに登録する

[METADATA.md](METADATA.md)に説明文と審査メモを用意しています。販売者情報、カテゴリ、価格、配信地域、年齢区分、輸出コンプライアンスはアカウント所有者が確認して登録します。Bundle IDを既存アプリと一致させ、バージョンとビルド番号が登録済みの値より進んでいることも確認してください。

今回のガイド画面は[screenshots](screenshots)に撮影済みです。提出前には実機のキーボード使用画面も追加してください。素材フォルダに残っている過去の画像は、現行画面との一致を確認するまで流用しないでください。必要なサイズは[Appleのスクリーンショット仕様](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)で確認できます。

キーボード拡張は、次のキーボードへの切り替えと、フルアクセスなしでの動作が必要です。拡張から起動できる他アプリはSettingsに限られます。[App Review 4.4.1](https://developer.apple.com/app-store/review/guidelines/#extensions)

## 用語と問い合わせ

- Archive：配布用にまとめたビルド。署名なしのArchiveだけではアップロードできません。
- App Group：本体アプリとキーボード拡張が設定や辞書を共有する領域。
- TestFlight：審査提出前に端末へ配布して動作確認するAppleのサービス。

実装の問題は[リポジトリのIssues](https://github.com/clearclown/PISMO_cyrillicJapaneseInput/issues)に再現手順を残してください。入力した文章や個人情報は削除してから共有します。
