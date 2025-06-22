# AI Chat - Foundation Models Framework

Apple の Foundation Models フレームワークを活用したSwiftUI ベースのAIチャットアプリケーションです。
Tool Calling 機能により、リアルタイムの天気予報取得が可能です。

## 🚀 主要機能

### ✨ Core Features
- **Apple Intelligence 統合**: Foundation Models フレームワークを使用
- **Tool Calling 対応**: 天気予報API との連携
- **SwiftUI + MVVM**: モダンなiOSアーキテクチャ
- **完全日本語対応**: すべてのUIとメッセージが日本語
- **エラーハンドリング**: 詳細なエラーダイアログとフォールバック機能

### 🌤️ Weather Tool Features
- **リアルタイム天気予報**: 気象庁データを活用
- **16都市対応**: 主要都市の詳細な気象情報
- **詳細情報**: 3日間予報、気温、降水確率、風速、波高
- **Tool Call 表示**: ツール使用時の明確な通知

## 📋 技術仕様

### 必要環境
- **iOS**: 26.0以上
- **Xcode**: 26.0以上
- **Swift**: 6.0
- **デバイス**: Apple Intelligence 対応機種

### 使用フレームワーク
- `FoundationModels` - Apple Intelligence統合
- `SwiftUI` - ユーザーインターフェース
- `Combine` - リアクティブプログラミング
- `Foundation` - 基本ライブラリ

## 🏗️ アーキテクチャ

### MVVM パターン
```
View Layer (SwiftUI)
├── ChatView.swift          # メインチャット画面
├── MessageRowView.swift    # メッセージ表示コンポーネント
├── MessageInputView.swift  # メッセージ入力コンポーネント
└── ContentView.swift       # 初期化・エラー管理

ViewModel Layer
└── ChatViewModel.swift     # チャット状態管理

Model Layer
└── ChatMessage.swift       # メッセージデータモデル

Service Layer
├── AIService.swift         # Foundation Models 統合
├── WeatherService.swift    # 天気予報API通信
└── WeatherTool.swift       # Tool Calling実装

Manager Layer
└── InitializationManager.swift  # アプリ初期化

Resource Layer
└── LocalizedString.swift   # 日本語文字列管理
```

## 🌟 Tool Calling Implementation

### WeatherTool 定義
```swift
struct WeatherTool: Tool {
    let name = "getWeather"
    let description = "都市の天気予報、気温、降水確率、風速、波を取得できます。"
    
    @Generable
    struct Arguments {
        @Guide(description: "The city to get weather information for")
        var city: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Weather API 呼び出し実装
    }
}
```

### 対応都市
東京、大阪、名古屋、福岡、札幌、仙台、広島、金沢、新潟、静岡、横浜、神戸、京都、熊本、鹿児島、那覇

## 📡 API統合

### 天気予報API
- **エンドポイント**: https://weather.tsukumijima.net/
- **データソース**: 気象庁公式データ
- **更新頻度**: リアルタイム
- **認証**: 不要（無料API）

### 取得可能データ
- 3日間天気予報（今日・明日・明後日）
- 最高・最低気温
- 6時間毎降水確率
- 風向・風速
- 波の高さ
- 天気概況文

## 🔧 セットアップ

### 1. プロジェクトクローン
```bash
git clone https://github.com/your-username/AI_Chat.git
cd AI_Chat
```

### 2. Xcode で開く
```bash
open AI_Chat.xcodeproj
```

### 3. Apple Intelligence 設定
1. iOS 26.0以上の対応デバイスを使用
2. 設定 > Apple Intelligence & Siri を開く
3. Apple Intelligence をオンに設定
4. 必要なモデルをダウンロード

### 4. ビルド・実行
- Xcode でビルド（⌘+B）
- シミュレーターまたは実機で実行（⌘+R）

## 💡 使用方法

### 基本的な会話
```
ユーザー: こんにちは
AI: こんにちは！何かお手伝いできることはありますか？天気予報もお聞きできます！
```

### 天気予報取得
```
ユーザー: 東京の天気はどうですか？
AI: 【東京都東京の天気予報】
    発表: 気象庁 - 2024/01/15 17:00:00
    
    【今日（2024-01-15）】
    天気: 晴れ
    最高気温: 12°C / 最低気温: 3°C
    ...
    
    🌤️ 気象庁のデータから最新の天気予報を取得しました。
```

## 🛠️ トラブルシューティング

### Apple Intelligence が利用できない場合
1. **対応デバイス確認**: iPhone 15 Pro/Pro Max 以上推奨
2. **iOS バージョン**: 18.0以上にアップデート
3. **設定確認**: Apple Intelligence & Siri の設定を確認
4. **モデルダウンロード**: 必要なAIモデルがダウンロード済みか確認

### よくあるエラー
- `ModelCatalog Error`: Apple Intelligence の初期化に失敗
- `Network Error`: インターネット接続を確認
- `City Not Found`: 対応都市一覧を確認
