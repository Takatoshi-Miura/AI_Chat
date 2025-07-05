import Foundation

/// チャットメッセージを表すモデル
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    let stepNumber: Int?
    
    init(text: String, isFromUser: Bool, stepNumber: Int? = nil) {
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.stepNumber = stepNumber
    }
    
    // Equatableプロトコルの実装
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id &&
               lhs.text == rhs.text &&
               lhs.isFromUser == rhs.isFromUser &&
               lhs.stepNumber == rhs.stepNumber
    }
}
