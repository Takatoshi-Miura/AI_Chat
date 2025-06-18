//
//  ChatMessage.swift
//  AI_Chat
//
//  Created by Claude on 2025/06/18.
//

import Foundation

/// チャットメッセージを表すモデル
struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(text: String, isFromUser: Bool) {
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = Date()
    }
} 