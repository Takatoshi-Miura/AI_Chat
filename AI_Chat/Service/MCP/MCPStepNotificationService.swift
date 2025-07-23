import Foundation
import SwiftUI
import Combine

/// MCPステップ通知を管理するグローバルサービス
@MainActor
class MCPStepNotificationService: ObservableObject {
    static let shared = MCPStepNotificationService()
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    // ステップ通知用のコールバック
    var onStepUpdate: ((String) -> Void)?
    
    private init() {}
    
    /// MCPステップを通知
    func notifyStep(_ message: String) {
        onStepUpdate?(message)
    }
    
    /// コールバックを設定
    func setStepUpdateCallback(_ callback: @escaping (String) -> Void) {
        onStepUpdate = callback
    }
    
    /// コールバックをクリア
    func clearStepUpdateCallback() {
        onStepUpdate = nil
    }
} 