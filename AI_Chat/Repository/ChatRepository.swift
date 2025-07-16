import Foundation
import Combine

/// チャットデータの永続化と管理を担当するRepository
protocol ChatRepositoryProtocol {
    /// チャットメッセージの一覧を取得
    func getMessages() -> [ChatMessage]
    
    /// メッセージを追加
    func addMessage(_ message: ChatMessage)
    
    /// メッセージをクリア
    func clearMessages()
    
    /// ウェルカムメッセージを追加
    func addWelcomeMessage()
}

@MainActor
class ChatRepository: ChatRepositoryProtocol, ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    
    init() {
        addWelcomeMessage()
    }
    
    func getMessages() -> [ChatMessage] {
        return messages
    }
    
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
    }
    
    func clearMessages() {
        messages.removeAll()
        addWelcomeMessage()
    }
    
    func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            text: LocalizedStrings.welcomeMessage,
            isFromUser: false
        )
        messages.append(welcomeMessage)
    }
    
    /// 初期化エラーメッセージを追加
    func addInitializationError(_ errorMessage: String) {
        let errorChatMessage = ChatMessage(
            text: "⚠️ 初期化エラー\n\n\(errorMessage)",
            isFromUser: false
        )
        addMessage(errorChatMessage)
    }
}