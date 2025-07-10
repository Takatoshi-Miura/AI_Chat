# AI Chat - MCP統合AIチャットアプリ

Apple の Foundation Models フレームワークとMCP（Model Context Protocol）を統合したSwiftUI ベースのAIチャットアプリケーションです。
MCPサーバーとの連携により、リアルタイムの天気予報などの外部ツールが利用可能です。

## 🚀 主要機能

### ✨ Core Features
- **Apple Intelligence 統合**: Foundation Models フレームワークを使用
- **MCP 統合**: Model Context ProtocolによるツールCallling
- **外部ツール連携**: 天気予報MCPサーバーとの通信
- **SwiftUI + MVVM**: モダンなiOSアーキテクチャ
- **完全日本語対応**: すべてのUIとメッセージが日本語
- **段階的応答表示**: MCPツール実行過程の可視化

### 🌤️ MCP Tool Features
- **リアルタイム天気予報**: MCPサーバー経由での気象情報取得
- **複数サーバー対応**: 将来的な機能拡張に対応
- **接続状況管理**: サーバー接続の監視と再接続機能
- **動的ツール生成**: MCPツールの自動検出と統合

## 📋 技術仕様

### 必要環境
- **iOS**: 26.0以上
- **Xcode**: 26.0以上
- **Swift**: 6.0
- **デバイス**: Apple Intelligence 対応機種

### 使用フレームワーク
- `FoundationModels` - Apple Intelligence統合
- `MCP` - Model Context Protocol クライアント
- `SwiftUI` - ユーザーインターフェース
- `Combine` - リアクティブプログラミング
- `Foundation` - 基本ライブラリ

### 依存関係
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) v0.9.0以上

## 🏗️ アーキテクチャ

### MVVM + MCP 統合パターン
```
View Layer (SwiftUI)
├── ChatView.swift               # メインチャット画面
├── MessageRowView.swift         # メッセージ表示コンポーネント
├── MessageInputView.swift       # メッセージ入力コンポーネント
└── ContentView.swift            # 初期化・エラー管理

ViewModel Layer
└── ChatViewModel.swift          # チャット状態管理

Model Layer
├── ChatMessage.swift            # メッセージデータモデル
└── DynamicMCPTool.swift         # 動的MCPツール

Service Layer
├── AIService.swift              # Foundation Models 統合
├── MCPClientService.swift       # MCPクライアント通信
├── DynamicMCPToolService.swift  # 動的ツール生成
├── StepByStepResponseService.swift # 段階的応答管理
└── MCPStepNotificationService.swift # ステップ通知

Manager Layer
└── InitializationManager.swift # アプリ初期化

Resource Layer
└── LocalizedString.swift        # 日本語文字列管理
```

## 🔗 MCP統合の仕組み

アプリは起動時にMCPサーバーに接続し、利用可能なツールを動的に検出してFoundation Models Frameworkのツールとして統合します。

## 📡 外部ツール統合

### 天気予報MCPサーバー
- **エンドポイント**: https://mcp-weather.get-weather.workers.dev
- **プロトコル**: Model Context Protocol (MCP)
- **データソース**: 気象庁公式データ
- **機能**: リアルタイム天気予報、気温、降水確率など

### 取得可能データ
- 都市別天気予報
- 気温情報
- 降水確率
- 風速・風向
- その他気象データ

## 🔧 セットアップ

### 1. プロジェクトクローン
```bash
git clone [repository-url]
cd AI_Chat
```

### 2. Xcode で開く
```bash
open AI_Chat.xcodeproj
```

### 3. 依存関係の解決
Xcodeが自動的にSwift Package Manager経由でMCP SDKをダウンロードします。

### 4. Apple Intelligence 設定
1. iOS 18.0以上の対応デバイスを使用
2. 設定 > Apple Intelligence & Siri を開く
3. Apple Intelligence をオンに設定
4. 必要なモデルをダウンロード

### 5. ビルド・実行
- Xcode でビルド（⌘+B）
- シミュレーターまたは実機で実行（⌘+R）

## 💡 使用方法

### 基本的な会話
```
ユーザー: こんにちは
AI: こんにちは！何かお手伝いできることはありますか？天気予報もお聞きできます！
```

### MCPツールの利用
```
ユーザー: 東京の天気はどうですか？
AI: [MCPサーバーへの接続を開始しています...]
    [✅ MCPツール 'get_weather' を実行中...]
    [✅ MCPツールの実行が完了しました]
    
    東京の天気予報をお調べしました。
    本日は晴れ、最高気温は25°C、最低気温は18°Cの予想です。
    降水確率は10%となっています。
```

### サーバー管理機能
- 接続状況の確認
- 個別サーバーの再接続
- 全サーバーの一括管理

## 🛠️ 開発・デバッグ

### MCPサーバー接続のテスト
1. アプリ上部のMCPステータス表示を確認
2. 「全再接続」ボタンで接続を再試行
3. 詳細ボタンでサーバー別接続状況を確認

### ログ確認
MCPStepNotificationServiceが各処理ステップをチャット画面に表示します。

## 🔧 トラブルシューティング

### Apple Intelligence が利用できない場合
1. **対応デバイス確認**: iPhone 15 Pro/Pro Max 以上推奨
2. **iOS バージョン**: 18.0以上にアップデート
3. **設定確認**: Apple Intelligence & Siri の設定を確認
4. **モデルダウンロード**: 必要なAIモデルがダウンロード済みか確認

### MCPサーバー接続エラー
1. **ネットワーク接続**: インターネット接続を確認
2. **サーバー状況**: MCPサーバーの稼働状況を確認
3. **再接続試行**: アプリ内の再接続機能を使用

### よくあるエラー
- `ModelCatalog Error`: Apple Intelligence の初期化に失敗
- `MCP Connection Error`: MCPサーバーへの接続に失敗
- `Tool Execution Error`: 外部ツールの実行に失敗

## 🌟 拡張可能性

### 新しいMCPサーバーの追加
`ChatViewModel`の`mcpServerURLs`配列に新しいサーバーURLを追加することで、他のMCPサーバーとの連携が可能です。

### カスタムツールの開発
MCPプロトコルに対応したカスタムサーバーを開発し、独自の機能を追加できます。

