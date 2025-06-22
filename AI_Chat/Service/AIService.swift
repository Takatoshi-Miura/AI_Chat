import Foundation
import Combine
import SwiftUI
import FoundationModels

@MainActor
class AIService {
    var errorMessage: String?
    
    init() {
        // Foundation Models Frameworkの初期化
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
            let systemPrompt = "あなたは親切で知識豊富なAIアシスタントです。日本語で丁寧に回答してください。Tool Callingを使用した際はそのことを回答に含めてください。"
            let response = try await generateLLMResponse(systemPrompt: systemPrompt, userMessage: message)
            return response
        } catch {
            throw AIServiceError.responseGenerationFailed
        }
    }
    
    /// Foundation Models Frameworkを使用してLLM応答を生成（Tool Calling対応）
    private func generateLLMResponse(systemPrompt: String, userMessage: String) async throws -> String {
        do {
            let session = LanguageModelSession(
                tools: [WeatherTool()],
                instructions: systemPrompt
            )
            
            let response = try await session.respond(to: userMessage)
            return response.content
        } catch let error {
            // エラーメッセージを構築
            var dialogMessage = "Apple Intelligence エラー\n\n"
            if let nsError = error as NSError? {
                // 具体的なエラー原因の特定と解決策
                let errorString = error.localizedDescription.lowercased()
                
                if errorString.contains("modelcatalog") {
                    dialogMessage += "モデルアセットが利用できません。\n\n"
                    dialogMessage += "解決策:\n"
                    dialogMessage += "• 設定 > Apple Intelligence & Siri を開く\n"
                    dialogMessage += "• Apple Intelligence がオンになっているか確認\n"
                    dialogMessage += "• モデルのダウンロードが完了しているか確認\n"
                    dialogMessage += "• デバイスが対応機種か確認\n\n"
                } else if errorString.contains("network") {
                    dialogMessage += "ネットワーク接続に問題があります。\n\n"
                    dialogMessage += "解決策:\n"
                    dialogMessage += "• インターネット接続を確認\n"
                    dialogMessage += "• しばらく時間をおいてから再試行\n\n"
                } else if errorString.contains("auth") {
                    dialogMessage += "認証に問題があります。\n\n"
                    dialogMessage += "解決策:\n"
                    dialogMessage += "• Apple IDでサインインしているか確認\n"
                    dialogMessage += "• デバイスを再起動\n\n"
                } else if errorString.contains("quota") {
                    dialogMessage += "使用量制限に達しました。\n\n"
                    dialogMessage += "しばらく時間をおいてから再度お試しください。\n\n"
                } else {
                    dialogMessage += "予期しないエラーが発生しました。\n\n"
                }
                
                // 詳細な技術情報を追加
                dialogMessage += "詳細情報:\n"
                dialogMessage += "Domain: \(nsError.domain)\n"
                dialogMessage += "Code: \(nsError.code)\n"
                dialogMessage += "Description: \(nsError.localizedDescription)"
                
            } else {
                dialogMessage += "エラー: \(error.localizedDescription)"
            }
            
            dialogMessage += "\n\n申し訳ございません。AIモデルの準備中です。設定でApple Intelligenceを確認してください。"
            
            // エラーメッセージを設定
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
