import Foundation
import Combine
import FoundationModels

@MainActor
class InitializationManager: ObservableObject {
    @Published var isInitialized = false
    @Published var errorMessage: String?
    
    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
    
    /// アプリの初期化を実行
    func initialize() async {
        await performInitialization()
        isInitialized = true
    }
    
    private func performInitialization() async {
        // Apple Intelligence状態のチェック
        await checkAppleIntelligenceStatus()
    }
    
    /// Apple Intelligenceの状態をチェック
    private func checkAppleIntelligenceStatus() async {
        if #available(iOS 18.1, macOS 15.1, *) {
            // Foundation Models Frameworkの利用可能性テスト
            do {
                let testSession = LanguageModelSession(instructions: "Test")
                _ = try await testSession.respond(to: "Hello")
            } catch {
                // エラーメッセージをチャット表示用に構築
                var chatMessage = "Apple Intelligence の初期化に失敗しました。\n\n"
                
                if let nsError = error as NSError? {
                    // 具体的なエラー原因の特定と解決策
                    if nsError.domain.contains("UnifiedAssetFramework") || nsError.code == 5000 {
                        chatMessage += "モデルアセットが利用できません。\n"
                        chatMessage += "設定 > Apple Intelligence & Siri でモデルのダウンロードを確認してください。"
                    } else if nsError.domain.contains("ModelInference") {
                        chatMessage += "Apple Intelligence サービスが一時的に利用できません。\n"
                        chatMessage += "しばらく時間をおいてから再度お試しください。"
                    } else {
                        chatMessage += "予期しないエラーが発生しました。\n"
                        chatMessage += "エラー: \(nsError.localizedDescription)"
                    }
                } else {
                    chatMessage += "エラー: \(error.localizedDescription)"
                }
                
                chatMessage += "\n\nアプリは基本機能で動作します。"
                
                // エラーメッセージを設定（チャット表示用）
                self.errorMessage = chatMessage
            }
        } else {
            errorMessage = "Apple Intelligence は iOS 18.1 以上で利用可能です。\n\nアプリは基本機能で動作します。"
        }
    }
} 
