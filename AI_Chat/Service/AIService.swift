import Foundation
import Combine
import SwiftUI
import FoundationModels

@MainActor
class AIService {
    var session: LanguageModelSession
    var errorMessage: String?
    
    private let mcpClient = MCPClientService()
    private let dynamicToolService: DynamicMCPToolService
    private var dynamicTools: [any FoundationModels.Tool] = []
    let systemPrompt = """
    あなたは親切で知識豊富なAIアシスタントです。日本語で丁寧に回答してください。
    外部情報が必要な場合は、用途に合ったFoundationModels.Toolを使用して回答してください。
    """
    
    init() {
        self.dynamicToolService = DynamicMCPToolService(mcpService: mcpClient)
        
        session = LanguageModelSession(
            instructions: systemPrompt
        )
    }
    
    /// MCPサーバーに接続して動的ツールを作成・追加
    /// - Parameter serverURL: MCPサーバーのURL
    func connectAndUpdateTools(serverURL: URL) async throws {
        // MCPサーバーに接続
        try await mcpClient.connect(to: serverURL)
        
        // 動的ツールを作成
        dynamicTools = dynamicToolService.createAllDynamicTools()
        
        // セッションを動的ツールで更新
        updateSessionWithDynamicTools()
        
        MCPStepNotificationService.shared.notifyStep("✅ MCPツールが利用可能になりました: \(dynamicTools.map { $0.name }.joined(separator: ", "))")
    }
    
    /// セッションを動的ツールで更新
    private func updateSessionWithDynamicTools() {
        var allTools: [any FoundationModels.Tool] = []
        allTools.append(contentsOf: dynamicTools)
        
        session = LanguageModelSession(
            tools: allTools,
            instructions: systemPrompt
        )
    }
    
    /// 利用可能な全ツールの説明を取得
    private func getAllAvailableToolsDescription() -> String {
        var descriptions = [""]
        
        for tool in dynamicTools {
            descriptions.append("- \(tool.name)：\(tool.description)")
        }
        
        return descriptions.joined(separator: "\n")
    }
    
    /// 利用可能な動的ツールの一覧を取得
    func getAvailableDynamicTools() -> [(name: String, description: String)] {
        return dynamicTools.map { (name: $0.name, description: $0.description) }
    }
    
    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
    
    /// メッセージをAIに送信して応答を取得
    func generateResponse(for message: String) async throws -> String {
        do {
            let response = try await performAIRequest(message: message)
            return response
        } catch {
            throw AIServiceError.responseGenerationFailed
        }
    }
    
    /// Foundation Models Frameworkを使用してAIリクエストを実行
    private func performAIRequest(message: String) async throws -> String {
        do {
            let response = try await generateLLMResponse(userMessage: message)
            return response
        } catch {
            throw AIServiceError.responseGenerationFailed
        }
    }
    
    /// Foundation Models Frameworkを使用してLLM応答を生成（Tool Calling対応）
    private func generateLLMResponse(userMessage: String) async throws -> String {
        do {
            let response = try await session.respond(to: userMessage)
            return response.content
        } catch let error {
            // エラーメッセージを構築
            var dialogMessage = "Apple Intelligence エラー\n\n"
            if (error as NSError?) != nil {
                let errorString = error.localizedDescription.lowercased()
                dialogMessage += errorString
            }
            self.errorMessage = dialogMessage
            return dialogMessage
        }
    }

}

/// AIサービスのエラー定義
enum AIServiceError: LocalizedError {
    case responseGenerationFailed
    case networkError
    case authenticationError
    
    var errorDescription: String? {
        switch self {
        case .responseGenerationFailed:
            return "AI応答の生成に失敗しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .authenticationError:
            return "認証エラーが発生しました"
        }
    }
} 
