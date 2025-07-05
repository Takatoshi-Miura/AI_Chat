import Foundation
import Combine

/// 段階的回答を管理するサービス
@MainActor
class StepByStepResponseService: ObservableObject {
    
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
        
        // 質問内容に応じて動的にステップを決定（処理時間のみ使用）
        let steps = determineSteps(for: userMessage)
        
        // 各ステップの処理時間をシミュレート（メッセージ表示なし）
        for step in steps {
            // ステップの実行時間をシミュレート
            try? await Task.sleep(nanoseconds: UInt64(step.duration * 1_000_000_000))
        }
        
        // 実際のAI応答を生成
        let finalResponse = await generateActualResponse(for: userMessage)
        
        // MCPステップ通知のコールバックをクリア
        MCPStepNotificationService.shared.clearStepUpdateCallback()
        
        onFinalResponse(finalResponse)
    }
    
    /// 質問内容に応じてステップを決定
    private func determineSteps(for message: String) -> [ResponseStep] {
        let lowercaseMessage = message.lowercased()
        
        // 天気関連の質問
        if lowercaseMessage.contains("天気") || lowercaseMessage.contains("気温") || 
           lowercaseMessage.contains("降水") || lowercaseMessage.contains("雨") {
            return [
                ResponseStep(message: "", duration: 0.5) // MCPサーバー処理時間のみ
            ]
        }
        
        // 計算や数学関連の質問
        if lowercaseMessage.contains("計算") || lowercaseMessage.contains("数") || 
           lowercaseMessage.contains("何") || lowercaseMessage.contains("いくつ") {
            return [
                ResponseStep(message: "", duration: 1.0)
            ]
        }
        
        // 説明や解説を求める質問
        if lowercaseMessage.contains("説明") || lowercaseMessage.contains("教え") || 
           lowercaseMessage.contains("とは") || lowercaseMessage.contains("について") {
            return [
                ResponseStep(message: "", duration: 1.5)
            ]
        }
        
        // 一般的な質問のデフォルトステップ
        return [
            ResponseStep(message: "", duration: 1.0)
        ]
    }
    
    /// 実際のAI応答を生成（既存のAIServiceを使用）
    private func generateActualResponse(for message: String) async -> String {
        do {
            let aiService = AIService()
            let response = try await aiService.generateResponse(for: message)
            return response
        } catch {
            return "申し訳ございません。回答の生成中にエラーが発生しました。もう一度お試しください。"
        }
    }
}

/// 回答ステップの定義
struct ResponseStep {
    let message: String
    let duration: Double
} 