import Foundation
import Combine

/// チャット関連の状態を管理するクラス
@MainActor
class ChatState: ObservableObject {
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    
    /// 入力テキストをクリア
    func clearInputText() {
        inputText = ""
    }
    
    /// ローディング状態を設定
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    /// エラーを設定
    func setError(_ error: String) {
        lastError = error
    }
    
    /// エラーをクリア
    func clearError() {
        lastError = nil
    }
    
    /// 入力が有効かチェック
    func isInputValid() -> Bool {
        return !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}