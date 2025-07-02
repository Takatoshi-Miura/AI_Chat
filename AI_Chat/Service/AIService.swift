import Foundation
import Combine
import SwiftUI
import FoundationModels

@MainActor
class AIService {
    var session: LanguageModelSession
    var errorMessage: String?
    
    init() {
        let systemPrompt = "あなたは親切で知識豊富なAIアシスタントです。日本語で丁寧に回答してください。"
        session = LanguageModelSession(
            tools: [WeatherMCPTool()],
            instructions: systemPrompt
        )
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
    
//    private func getToolCallHistory(session: LanguageModelSession) {
//        switch session.transcript {
//        case .instructions(let instructions):
//            // Display the instructions the model uses.
//        case .prompt(let prompt):
//            // Display the prompt made to the model.
//        case .toolCall(let call):
//            // Display the call details for a tool, like the tool name and arguments.
//        case .toolOutput(let output):
//            // Display the output that a tool provides back to the model.
//        case .response(let response):
//            // Display the response from the model.
//        }
//    }
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
