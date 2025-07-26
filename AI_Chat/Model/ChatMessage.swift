import Foundation
import UIKit

/// チャットメッセージを表すモデル
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    let stepNumber: Int?
    let imageData: Data?
    
    init(text: String, isFromUser: Bool, stepNumber: Int? = nil, imageData: Data? = nil) {
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.stepNumber = stepNumber
        self.imageData = imageData
    }
    
    // UIImageを取得するヘルパープロパティ
    var image: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
    
    // Equatableプロトコルの実装
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id &&
               lhs.text == rhs.text &&
               lhs.isFromUser == rhs.isFromUser &&
               lhs.stepNumber == rhs.stepNumber &&
               lhs.imageData == rhs.imageData
    }
}
