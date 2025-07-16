import Foundation
import Combine

/// チャット関連の操作を統合するService
protocol ChatServiceProtocol {
    /// メッセージを送信してAI応答を取得
    func sendMessage(
        _ message: String,
        onStepUpdate: @escaping (ChatMessage) -> Void,
        onFinalResponse: @escaping (String) -> Void
    ) async
    
    /// エラーメッセージがあるかチェック
    func hasError() -> Bool
    
    /// エラーメッセージを取得
    func getErrorMessage() -> String?
    
    /// エラーをクリア
    func clearError()
}

@MainActor
class ChatService: ChatServiceProtocol, ObservableObject {
    private let aiService: AIService
    private let stepByStepService: StepByStepResponseService
    
    init(aiService: AIService) {
        self.aiService = aiService
        self.stepByStepService = StepByStepResponseService(aiService: aiService)
    }
    
    func sendMessage(
        _ message: String,
        onStepUpdate: @escaping (ChatMessage) -> Void,
        onFinalResponse: @escaping (String) -> Void
    ) async {
        // 段階的回答サービスを使用
        await stepByStepService.generateStepByStepResponse(
            for: message,
            onStepUpdate: onStepUpdate,
            onFinalResponse: onFinalResponse
        )
    }
    
    func hasError() -> Bool {
        return aiService.errorMessage != nil
    }
    
    func getErrorMessage() -> String? {
        return aiService.errorMessage
    }
    
    func clearError() {
        aiService.clearError()
    }
}