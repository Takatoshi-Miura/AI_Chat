import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    
    // 依存関係
    private let chatRepository: ChatRepository
    private let chatService: ChatServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties
    var messages: [ChatMessage] {
        chatRepository.getMessages()
    }
    
    var inputText: String {
        get { AppState.shared.chatState.inputText }
        set { AppState.shared.chatState.inputText = newValue }
    }
    
    init(
        chatRepository: ChatRepository,
        chatService: ChatServiceProtocol
    ) {
        self.chatRepository = chatRepository
        self.chatService = chatService
        
        setupObservers()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // ChatRepositoryの変更を監視
        chatRepository.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // ChatStateの変更を監視
        AppState.shared.chatState.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    /// 初期化エラーをチャットに追加
    func addInitializationError(_ errorMessage: String) {
        chatRepository.addInitializationError(errorMessage)
    }
    
    /// メッセージを送信する
    func sendMessage() {
        guard AppState.shared.chatState.isInputValid() else { return }
        
        let userMessage = inputText
        AppState.shared.chatState.clearInputText()
        
        // ユーザーメッセージを追加
        chatRepository.addMessage(ChatMessage(text: userMessage, isFromUser: true))
        
        // AI応答を生成
        Task {
            await generateAIResponse(for: userMessage)
        }
    }
    
    /// AI応答を生成する
    private func generateAIResponse(for message: String) async {
        isLoading = true
        AppState.shared.chatState.setLoading(true)
        
        await chatService.sendMessage(
            message,
            onStepUpdate: { [weak self] stepMessage in
                self?.chatRepository.addMessage(stepMessage)
            },
            onFinalResponse: { [weak self] finalResponse in
                self?.completeAIResponse(with: finalResponse)
            }
        )
        
        isLoading = false
        AppState.shared.chatState.setLoading(false)
    }
 
    /// AI応答を完了し、最終回答を追加
    private func completeAIResponse(with finalResponse: String) {
        let finalMessage = ChatMessage(
            text: finalResponse,
            isFromUser: false
        )
        chatRepository.addMessage(finalMessage)
        
        // エラーがある場合はエラーメッセージをチャットに追加
        if chatService.hasError() {
            if let errorMessage = chatService.getErrorMessage() {
                let errorChatMessage = ChatMessage(text: "⚠️ \(errorMessage)", isFromUser: false)
                chatRepository.addMessage(errorChatMessage)
                chatService.clearError()
            }
        }
    }
    
    /// チャット履歴をクリア
    func clearMessages() {
        chatRepository.clearMessages()
    }
} 
