//
//  LocalizedString.swift
//  AI_Chat
//
//  Created by Claude on 2025/06/18.
//

import Foundation

/// アプリで使用するローカライズされた文字列
struct LocalizedStrings {
    static let welcomeMessage = NSLocalizedString("welcome_message", comment: "ウェルカムメッセージ")
    static let messagePlaceholder = NSLocalizedString("message_placeholder", comment: "メッセージ入力欄のプレースホルダー")
    static let sendButton = NSLocalizedString("send_button", comment: "送信ボタン")
    static let errorOccurred = NSLocalizedString("error_occurred", comment: "エラー発生時のメッセージ")
    static let clearButton = NSLocalizedString("clear_button", comment: "クリアボタン")
    static let aiChat = NSLocalizedString("ai_chat", comment: "AIチャットのタイトル")
} 