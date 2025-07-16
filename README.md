# AI Chat - MCP統合AIチャットアプリ

Apple の Foundation Models フレームワークとMCP（Model Context Protocol）を統合したSwiftUI ベースのAIチャットアプリケーションです。
MCPサーバーとの連携により、リアルタイムの天気予報などの外部ツールがOAuth認証付きで利用可能です。

## 🚀 主要機能

### ✨ Core Features
- **Apple Intelligence 統合**: Foundation Models フレームワークを使用
- **MCP 統合**: Model Context ProtocolによるTool Calling
- **OAuth 2.0 認証**: MCPサーバーとの安全な接続
- **外部ツール連携**: 天気予報MCPサーバーとの通信
- **SwiftUI + MVVM**: モダンなiOSアーキテクチャ
- **完全日本語対応**: すべてのUIとメッセージが日本語
- **段階的応答表示**: MCPツール実行過程の可視化

### 🌤️ MCP Tool Features
- **リアルタイム天気予報**: MCPサーバー経由での気象情報取得
- **複数サーバー対応**: 将来的な機能拡張に対応
- **OAuth認証管理**: サーバー別の認証状態管理
- **接続状況管理**: サーバー接続の監視と再接続機能
- **動的ツール生成**: MCPツールの自動検出と統合
- **トークン永続化**: 認証トークンの安全な保存

## 📋 技術仕様

### 必要環境
- **iOS**: 26.0以上 (iOS 18.2以上)
- **Xcode**: 26.0以上
- **Swift**: 6.0
- **デバイス**: Apple Intelligence 対応機種

### 使用フレームワーク
- `FoundationModels` - Apple Intelligence統合
- `MCP` - Model Context Protocol クライアント
- `SwiftUI` - ユーザーインターフェース
- `Combine` - リアクティブプログラミング
- `Foundation` - 基本ライブラリ
- `AuthenticationServices` - OAuth 2.0 認証

### 依存関係
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) v1.0.0以上

## 🏗️ アーキテクチャ

### MVVM + Dependency Injection パターン
```
View Layer (SwiftUI)
├── ContentView.swift                    # 初期化・エラー管理
├── ChatView.swift                       # メインチャット画面
├── OAuthView.swift                      # OAuth認証管理
├── OAuthWebView.swift                   # OAuth認証Web画面
├── AuthenticationManagementView.swift   # 認証管理画面
└── Common/                              # 共通コンポーネント

ViewModel Layer
├── ChatViewModel.swift                  # チャット状態管理
├── MCPConnectionViewModel.swift         # MCP接続状態管理
└── AuthenticationViewModel.swift       # 認証状態管理

Model Layer
├── ChatMessage.swift                    # メッセージデータモデル
└── DynamicMCPTool.swift                 # 動的MCPツール

Service Layer
├── AIService.swift                      # Foundation Models 統合
├── ChatService.swift                    # チャット統合サービス
├── MCPClientService.swift               # MCPクライアント通信
├── MCPConnectionService.swift           # MCP接続管理
├── DynamicMCPToolService.swift          # 動的ツール生成
├── StepByStepResponseService.swift      # 段階的応答管理
├── MCPStepNotificationService.swift     # ステップ通知
├── OAuthService.swift                   # OAuth 2.0 認証
├── AuthenticationService.swift          # 認証統合サービス
└── AuthenticatedHTTPTransport.swift     # 認証付きHTTPトランスポート

Repository Layer
├── ChatRepository.swift                 # チャットデータ管理
└── MCPConnectionRepository.swift        # MCP接続状態管理

State Layer
├── AppState.swift                       # アプリ全体状態
├── ChatState.swift                      # チャット状態
└── ConnectionState.swift                # 接続状態

Manager Layer
└── InitializationManager.swift          # アプリ初期化

Container Layer
├── ServiceContainer.swift               # 依存関係注入コンテナ
└── ViewModelFactory.swift               # ViewModelファクトリー

Resource Layer
└── LocalizedString.swift                # 日本語文字列管理
```

## 🔗 MCP統合の仕組み

1. **初期化**: アプリ起動時にMCPサーバーへの接続を試行
2. **OAuth認証**: 各MCPサーバーでOAuth 2.0認証を実行
3. **ツール検出**: 接続後にサーバーから利用可能なツールを取得
4. **動的統合**: MCPツールをFoundation Models Frameworkのツールに変換
5. **セッション更新**: 新しいツールでLanguageModelSessionを更新

## 📡 外部ツール統合

### 天気予報MCPサーバー
- **エンドポイント**: https://mcp-weather.get-weather.workers.dev
- **認証方式**: OAuth 2.0 (Bearer Token)
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
1. iOS 18.2以上の対応デバイスを使用
2. 設定 > Apple Intelligence & Siri を開く
3. Apple Intelligence をオンに設定
4. 必要なモデルをダウンロード

### 5. OAuth設定（必要に応じて）
`OAuthService.swift`で認証情報を確認・更新:
- `clientId`
- `clientSecret`
- `redirectUri`

### 6. ビルド・実行
- Xcode でビルド（⌘+B）
- シミュレーターまたは実機で実行（⌘+R）

## 💡 使用方法

### 初回起動時
1. アプリが自動的にApple Intelligenceの状態をチェック
2. MCPサーバーへの接続と認証を実行
3. OAuth認証画面が表示される場合があります

### 基本的な会話
```
ユーザー: こんにちは
AI: こんにちは！何かお手伝いできることはありますか？天気予報もお聞きできます！
```

### MCPツールの利用
```
ユーザー: 東京の天気はどうですか？
AI: [MCPサーバーへの接続を開始しています...]
    [OAuth認証を確認しています...]
    [✅ MCP サーバーに接続完了]
    [✅ MCPツール 'get_weather_overview' を実行中...]
    [✅ MCPツールの実行が完了しました]
    
    東京の天気予報をお調べしました。
    本日は晴れ、最高気温は25°C、最低気温は18°Cの予想です。
    降水確率は10%となっています。
```

### OAuth認証管理
- 画面上部のMCPステータス表示から詳細画面にアクセス
- サーバー別の認証状態確認
- 個別の再認証実行
- トークンの管理

## 🛠️ 開発・デバッグ

### MCPサーバー接続のテスト
1. アプリ上部のMCPステータス表示を確認
2. 「全再接続」ボタンで接続を再試行
3. 「詳細」ボタンでサーバー別接続状況を確認
4. OAuth認証が必要な場合は自動的に認証画面が表示

### ログ確認
- `MCPStepNotificationService`が各処理ステップをチャット画面に表示
- OAuth認証の詳細もリアルタイムで確認可能

### デバッグ機能
- サーバー別接続状況の詳細表示
- 認証トークンの有効性確認
- ツール一覧の動的更新

## 🔧 トラブルシューティング

### Apple Intelligence が利用できない場合
1. **対応デバイス確認**: iPhone 15 Pro/Pro Max 以上推奨
2. **iOS バージョン**: 18.2以上にアップデート
3. **設定確認**: Apple Intelligence & Siri の設定を確認
4. **モデルダウンロード**: 必要なAIモデルがダウンロード済みか確認

### MCPサーバー接続エラー
1. **ネットワーク接続**: インターネット接続を確認
2. **OAuth認証**: 認証トークンの有効性を確認
3. **サーバー状況**: MCPサーバーの稼働状況を確認
4. **再認証**: アプリ内の再認証機能を使用

### OAuth認証エラー
1. **リダイレクトURI**: URL Schemeの設定を確認
2. **認証情報**: Client IDとSecretの正確性を確認
3. **トークン期限**: 保存されたトークンの有効期限を確認
4. **手動認証**: 認証管理画面から手動で再認証を実行

### よくあるエラー
- `ModelCatalog Error`: Apple Intelligence の初期化に失敗
- `MCP Connection Error`: MCPサーバーへの接続に失敗
- `OAuth Authentication Error`: OAuth認証に失敗
- `Tool Execution Error`: 外部ツールの実行に失敗
- `Token Validation Error`: 認証トークンの検証に失敗

## 🌟 拡張可能性

### 新しいMCPサーバーの追加
`MCPConnectionRepository.swift`の`mcpServerURLs`配列に新しいサーバーURLを追加:

```swift
let mcpServerURLs: [URL] = [
    URL(string: "https://mcp-weather.get-weather.workers.dev")!,
    URL(string: "https://your-new-mcp-server.com")!  // 新規追加
]
```

### OAuth設定のカスタマイズ
各MCPサーバーに応じてOAuth設定を調整:
- `OAuthService.swift`でクライアント情報を更新
- `AuthenticationService.swift`で認証フローをカスタマイズ

### カスタムツールの開発
1. MCPプロトコルに対応したカスタムサーバーを開発
2. OAuth 2.0認証エンドポイントを実装
3. アプリの設定に新しいサーバーを追加

### UI/UXの拡張
- `ChatView.swift`でチャット画面のカスタマイズ
- `AuthenticationManagementView.swift`で認証管理機能の拡張
- `LocalizedString.swift`で多言語対応の追加

## 📝 リリース情報

### Version 1.0
- Apple Intelligence統合
- MCP Protocol対応
- OAuth 2.0 認証
- 天気予報ツール統合
- 日本語完全対応

