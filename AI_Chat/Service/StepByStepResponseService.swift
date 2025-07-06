import Foundation
import Combine

/// 段階的回答を管理するサービス
@MainActor
class StepByStepResponseService: ObservableObject {
    
    private weak var aiService: AIService?
    
    init(aiService: AIService? = nil) {
        self.aiService = aiService
    }
    
    /// AIServiceインスタンスを設定
    func setAIService(_ service: AIService) {
        self.aiService = service
    }
    
    /// 段階的回答を実行
    /// - Parameters:
    ///   - userMessage: ユーザーのメッセージ
    ///   - onStepUpdate: 各ステップの更新時に呼ばれるコールバック
    ///   - onFinalResponse: 最終回答が完了した時に呼ばれるコールバック
    func generateStepByStepResponse(
        for userMessage: String,
        onStepUpdate: @escaping (ChatMessage) -> Void,
        onFinalResponse: @escaping (String) -> Void
    ) async {
        
        // MCPステップ通知のコールバックを設定
        MCPStepNotificationService.shared.setStepUpdateCallback { message in
            let mcpMessage = ChatMessage(
                text: message,
                isFromUser: false
            )
            onStepUpdate(mcpMessage)
        }
        
        // AI応答を生成
        let finalResponse = await generateActualResponse(for: userMessage)
        
        // MCPステップ通知のコールバックをクリア
        MCPStepNotificationService.shared.clearStepUpdateCallback()
        
        onFinalResponse(finalResponse)
    }
    
    /// 実際のAI応答を生成（設定されたAIServiceを使用）
    private func generateActualResponse(for message: String) async -> String {
        guard let aiService = aiService else {
            return "申し訳ございません。AIサービスが利用できません。"
        }
        
        do {
            let response = try await aiService.generateResponse(for: message)
            return response
        } catch {
            return "申し訳ございません。回答の生成中にエラーが発生しました。もう一度お試しください。"
        }
    }
} 
