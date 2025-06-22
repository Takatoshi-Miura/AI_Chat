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
                // エラーメッセージを構築してダイアログ表示用に設定
                var dialogMessage = "Apple Intelligence初期化エラー\n\n"
                
                if let nsError = error as NSError? {
                    if let failureReason = nsError.localizedFailureReason {
                        print("   Failure Reason: \(failureReason)")
                    }
                    
                    // 具体的なエラー原因の特定と解決策
                    if nsError.domain.contains("UnifiedAssetFramework") || nsError.code == 5000 {
                        dialogMessage += "モデルアセットが利用できません。\n\n"
                        dialogMessage += "解決策:\n"
                        dialogMessage += "1. 設定 > Apple Intelligence & Siri を開く\n"
                        dialogMessage += "2. Apple Intelligence がオンになっているか確認\n"
                        dialogMessage += "3. モデルのダウンロードが完了しているか確認\n"
                        dialogMessage += "4. デバイスが対応機種か確認 (iPhone 15 Pro以上)\n"
                        dialogMessage += "5. デバイスを再起動してみる\n\n"
                    } else if nsError.domain.contains("ModelInference") {
                        dialogMessage += "Apple Intelligence サービスが一時的に利用できません。\n\n"
                        dialogMessage += "しばらく時間をおいてから再度お試しください。\n\n"
                    } else {
                        dialogMessage += "予期しないエラーが発生しました。\n\n"
                    }
                    
                    // 詳細なエラー情報を追加
                    dialogMessage += "詳細情報:\n"
                    dialogMessage += "Domain: \(nsError.domain)\n"
                    dialogMessage += "Code: \(nsError.code)\n"
                    dialogMessage += "Description: \(nsError.localizedDescription)"
                    
                } else {
                    dialogMessage += "エラー: \(error.localizedDescription)"
                }
                
                dialogMessage += "\n\nアプリは開発モードで動作します。"
                
                // エラーメッセージを設定（ダイアログ表示用）
                self.errorMessage = dialogMessage
            }
        } else {
            print("Apple Intelligence: Not available on this OS version")
            print("Requires iOS 18.1+ or macOS 15.1+")
        }
    }
} 
