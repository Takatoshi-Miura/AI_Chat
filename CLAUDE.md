# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

本アプリは、Foundation Models Frameworkを利用してApple IntelligenceのLLMとの会話を行い、
Tool Callingを通してMCPツールを利用するチャットアプリです。
SwiftUIを利用し、MVVMアーキテクチャを採用しています。
アプリは日本語のみ対応し、iOS 18以上をターゲットとしています。

## アプリの仕様

アプリの画面はAIとのチャット画面のみです。
ユーザは画面下部の入力欄にテキストを入力でき、送信ボタンを押すとAIにテキストを送信できます。
ユーザから受け取ったテキストは、そのままFoudation Models Frameworkを使ってLLMへと渡されます。
LLMからの回答が自動でチャット欄に返され、ユーザもそれを確認できます。
ユーザやAIが送信したメッセージはチャット画面に残り、スクロールすることで会話の履歴を閲覧できます。

## ビルドコマンド

### ビルドと実行
```bash
# Xcodeでプロジェクトを開く
open SportsNote_iOS.xcodeproj

# コマンドラインからビルド（xcodebuildが利用可能な場合）
xcodebuild -project SportsNote_iOS.xcodeproj -scheme SportsNote_iOS -destination 'platform=iOS Simulator,name=iPhone 15' build

# テスト実行
xcodebuild -project SportsNote_iOS.xcodeproj -scheme SportsNote_iOS -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## 依存関係
- Swift Package Managerを使用（依存関係はXcodeが自動解決）
- 主要な依存関係：Foundation Models Framework
- Foundation Models Frameworkについては、下記のリンクを参照
https://developer.apple.com/documentation/foundationmodels

## アーキテクチャ概要

### MVVMパターンの実装
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      View       │◄──►│   ViewModel     │◄──►│     Model       │
│   (SwiftUI)     │    │ (ObservableObject)   │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Model層**: オブジェクト

**ViewModel層**: @Publishedプロパティを持つObservableObjectクラス
- 命名規則: `[Entity]ViewModel.swift`（例: `TaskViewModel.swift`）
- リアクティブプログラミングにCombineを使用

**View層**: 機能別に整理されたSwiftUIビュー
- 共通コンポーネントは `View/Common/`
- 機能固有のビューはサブディレクトリ

### データ管理
- 必要があればUserDefaultsでデータの永続化を行う

### 主要なマネージャー
- `InitializationManager`: 初回起動時のセットアップ

## 開発ガイドライン

### コードパターン
- ViewModelとUI関連クラスには`@MainActor`を使用
- ユーザー向けテキストには`LocalizedStrings`を使用
- 既存の命名規則に従う（プロパティはcamelCase、型はPascalCase）

### 文字列リソース
- 文字列は`ja.lproj/Localizable.strings`で定義
- `Resource/LocalizedString.swift`の`LocalizedStrings`構造体経由でアクセス

### テスト
- Xcodeの組み込みテストフレームワークを使用

## プロジェクト設定からのコーディングルール

### SwiftUI/MVVM要件
- Swift6に対応
- 厳密なMVVM分離の維持（Model-View-ViewModel）
- SwiftUIの宣言的構文を使用
- リアクティブプログラミングにCombineを活用
- iOS 18以上の最小ターゲット
- サードパーティライブラリよりもApple純正フレームワークを優先
- コンポーネントの再利用性を重視
- 新機能には既存のコードパターンと最小限の変更を使用
- swiftformatで自動整形
- コメントを適切に記述

### 多言語化ルール
- すべてのユーザー向け文字列は`Localizable.strings`で定義する必要がある
- `LocalizedStrings`構造体経由で文字列にアクセス
- 日本語をサポート

## コミュニケーションガイドライン

### 言語設定
- **このコードベースで作業する際は常に日本語で回答する**
- 開発チームは主に日本語でコミュニケーションを行う
- コードコメントは標準的な日本語で記述する
- 技術的な説明は日本語で提供する