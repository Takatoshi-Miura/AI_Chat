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
            let systemPrompt = "あなたは親切で知識豊富なAIアシスタントです。日本語で丁寧に回答してください。"
            let response = try await generateLLMResponse(systemPrompt: systemPrompt, userMessage: message)
            return response
        } catch {
            throw AIServiceError.responseGenerationFailed
        }
    }
    
    /// Foundation Models Frameworkを使用してLLM応答を生成
    private func generateLLMResponse(systemPrompt: String, userMessage: String) async throws -> String {
        do {
            let session = LanguageModelSession(instructions: systemPrompt)
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
            
            dialogMessage += "\n\nフォールバック実装で応答します。"
            
            // エラーメッセージを設定
            self.errorMessage = dialogMessage
            
            // フォールバック実装を使用
            return generateFallbackResponse(for: userMessage)
        }
    }
    
    /// フォールバック用の応答生成（モデルが利用できない場合）
    private func generateFallbackResponse(for userMessage: String) -> String {
        let responses = [
            "「\(userMessage)」についてお答えします。\n\n※ 現在Apple Intelligenceが利用できないため、開発モードで動作しています。実際のAI機能を利用するには、対応デバイスでApple Intelligenceを有効にしてください。",
            "ご質問の「\(userMessage)」について考えてみます。\n\n※ Apple Intelligenceモデルが準備中です。しばらくお待ちください。",
            "「\(userMessage)」に関してお答えします。\n\n※ 現在はテストモードで動作しています。",
            "なるほど、「\(userMessage)」ですね。\n\n※ Apple Intelligence機能の準備が完了次第、より詳細な回答が可能になります。"
        ]
        
        return responses.randomElement() ?? "申し訳ございません。AIモデルの準備中です。設定でApple Intelligenceを確認してください。"
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
