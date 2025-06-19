//
//  AIService.swift
//  AI_Chat
//
//  Created by Claude on 2025/06/18.
//

import Foundation
import FoundationModels

/// AIとの通信を管理するサービス
@MainActor
class AIService {
    
    init() {
        // Foundation Models Frameworkの初期化
    }
    
    /// メッセージをAIに送信して応答を取得
    func generateResponse(for message: String) async throws -> String {
        do {
            let response = try await performAIRequest(message: message)
            return response
        } catch {
            print("AI応答生成エラー: \(error)")
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
            print("Foundation Models Framework Error: \(error)")
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
            print("🔴 === Foundation Models Framework Error ===")
            print("Error: \(error)")
            print("Error Type: \(type(of: error))")
            
            // 具体的なエラーメッセージを確認
            if let nsError = error as NSError? {
                print("NSError Domain: \(nsError.domain)")
                print("NSError Code: \(nsError.code)")
                print("NSError Description: \(nsError.localizedDescription)")
                if let failureReason = nsError.localizedFailureReason {
                    print("NSError Failure Reason: \(failureReason)")
                }
                if let userInfo = nsError.userInfo as? [String: Any] {
                    print("NSError UserInfo: \(userInfo)")
                }
            }
            
            // より詳細なエラー分析
            let errorString = error.localizedDescription.lowercased()
            print("🔍 Error Analysis:")
            
            if errorString.contains("modelcatalog") {
                print("❌ Model Catalog Error - モデルアセットが見つかりません")
                print("💡 対処法: 設定 > Apple Intelligence & Siri でモデルダウンロードを確認")
            } else if errorString.contains("network") {
                print("❌ Network Error - ネットワーク接続の問題")
            } else if errorString.contains("auth") {
                print("❌ Authentication Error - 認証の問題")
            } else if errorString.contains("quota") {
                print("❌ Quota Error - 使用量制限に達しました")
            } else {
                print("❌ Unknown Error - 未知のエラー")
            }
            
            print("🔄 フォールバック実装に切り替えます")
            print("============================================")
            
            // 全てのエラーでフォールバック実装を使用
            return generateFallbackResponse(for: userMessage)
        }
    }
    
    /// フォールバック用の応答生成（モデルが利用できない場合）
    private func generateFallbackResponse(for userMessage: String) -> String {
        print("📱 フォールバック実装を使用してメッセージ「\(userMessage)」に応答します")
        
        let responses = [
            "「\(userMessage)」についてお答えします。\n\n※ 現在Apple Intelligenceが利用できないため、開発モードで動作しています。実際のAI機能を利用するには、対応デバイスでApple Intelligenceを有効にしてください。",
            "ご質問の「\(userMessage)」について考えてみます。\n\n※ Apple Intelligenceモデルが準備中です。しばらくお待ちください。",
            "「\(userMessage)」に関してお答えします。\n\n※ 現在はテストモードで動作しています。",
            "なるほど、「\(userMessage)」ですね。\n\n※ Apple Intelligence機能の準備が完了次第、より詳細な回答が可能になります。"
        ]
        
        let response = responses.randomElement() ?? "申し訳ございません。AIモデルの準備中です。設定でApple Intelligenceを確認してください。"
        print("📤 フォールバック応答: \(response)")
        return response
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
