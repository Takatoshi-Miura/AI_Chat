import Foundation
import Combine
import FoundationModels

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var aiService = AIService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 初期化時にウェルカムメッセージを追加
        messages.append(ChatMessage(text: LocalizedStrings.welcomeMessage, isFromUser: false))
        
        // AIServiceのエラーメッセージは直接参照する形に変更
    }
    
    /// メッセージを送信する
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = inputText
        inputText = ""
        
        // ユーザーメッセージを追加
        messages.append(ChatMessage(text: userMessage, isFromUser: true))
        
        // AI応答を取得
        Task {
            await generateAIResponse(for: userMessage)
        }
    }
    
    /// AI応答を生成する
    private func generateAIResponse(for message: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await generateResponse(for: message)
            messages.append(ChatMessage(text: response, isFromUser: false))
            
            // AIServiceでエラーが発生した場合はエラーメッセージを取得
            if let aiServiceError = aiService.errorMessage {
                errorMessage = aiServiceError
            }
        } catch {
            errorMessage = LocalizedStrings.errorOccurred
        }
        
        isLoading = false
    }
    
    /// Foundation Models Frameworkを使用してAI応答を生成
    private func generateResponse(for message: String) async throws -> String {
        return try await aiService.generateResponse(for: message)
    }
    
    /// チャット履歴をクリア
    func clearMessages() {
        messages = [ChatMessage(text: LocalizedStrings.welcomeMessage, isFromUser: false)]
    }
    
    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
        aiService.clearError()
    }
} 
