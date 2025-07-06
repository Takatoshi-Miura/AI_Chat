import Foundation
import Combine
import FoundationModels

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var dynamicToolsStatus: String = "動的ツール: 未接続"
    
    private var aiService = AIService()
    private var stepByStepService: StepByStepResponseService
    private var cancellables = Set<AnyCancellable>()
    
    // 段階的回答の一時的なメッセージIDを追跡
    private var temporaryMessageIds: Set<UUID> = []
    
    init() {
        // StepByStepResponseServiceを同じAIServiceインスタンスで初期化
        self.stepByStepService = StepByStepResponseService(aiService: aiService)
        
        // 初期化時にウェルカムメッセージを追加
        messages.append(ChatMessage(text: LocalizedStrings.welcomeMessage, isFromUser: false))
        
        // 動的MCPツールの初期化を実行
        initializeDynamicTools()
    }
    
    /// 動的MCPツールを初期化
    private func initializeDynamicTools() {
        Task {
            await setupDynamicMCPTools()
        }
    }
    
    /// 動的MCPツールを設定
    private func setupDynamicMCPTools() async {
        guard let serverURL = URL(string: "https://mcp-weather.get-weather.workers.dev") else {
            dynamicToolsStatus = "動的ツール: URL設定エラー"
            return
        }
        
        do {
            dynamicToolsStatus = "動的ツール: 接続中..."
            
            // MCPサーバーに接続して動的ツールを設定
            try await aiService.connectAndUpdateTools(serverURL: serverURL)
            
            let availableTools = aiService.getAvailableDynamicTools()
            if !availableTools.isEmpty {
                let toolNames = availableTools.map { $0.name }.joined(separator: ", ")
                dynamicToolsStatus = "動的ツール: 利用可能 (\(toolNames))"
                
                // 利用可能なツールの情報をメッセージに追加
                let toolsMessage = "🔧 動的MCPツールが利用可能になりました:\n\(availableTools.map { "・\($0.name): \($0.description)" }.joined(separator: "\n"))"
                messages.append(ChatMessage(text: toolsMessage, isFromUser: false))
            } else {
                dynamicToolsStatus = "動的ツール: ツールが見つかりませんでした"
            }
            
        } catch {
            dynamicToolsStatus = "動的ツール: 接続エラー - \(error.localizedDescription)"
            print("動的MCPツール初期化エラー: \(error)")
            
            // エラーメッセージをチャットに追加
            let errorMessage = "⚠️ 動的MCPツールの初期化に失敗しました。基本機能は利用可能です。"
            messages.append(ChatMessage(text: errorMessage, isFromUser: false))
        }
    }
    
    /// 動的ツールの再接続を試行
    func retryDynamicToolsConnection() {
        Task {
            await setupDynamicMCPTools()
        }
    }
    
    /// メッセージを送信する
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = inputText
        inputText = ""
        
        // ユーザーメッセージを追加
        messages.append(ChatMessage(text: userMessage, isFromUser: true))
        
        // 段階的AI応答を開始
        Task {
            await generateStepByStepAIResponse(for: userMessage)
        }
    }
    
    /// 段階的AI応答を生成する
    private func generateStepByStepAIResponse(for message: String) async {
        isLoading = true
        errorMessage = nil
        
        // 段階的回答サービスを使用
        await stepByStepService.generateStepByStepResponse(
            for: message,
            onStepUpdate: { [weak self] stepMessage in
                Task { @MainActor in
                    self?.addTemporaryMessage(stepMessage)
                }
            },
            onFinalResponse: { [weak self] finalResponse in
                Task { @MainActor in
                    self?.completeStepByStepResponse(with: finalResponse)
                }
            }
        )
        
        isLoading = false
    }
    
    /// 一時的なステップメッセージを追加
    private func addTemporaryMessage(_ message: ChatMessage) {
        // 一時的なメッセージも履歴に残すため、削除処理をコメントアウト
        // removeTemporaryMessages()
        
        // 新しいメッセージを追加（一時的フラグは維持するが削除しない）
        messages.append(message)
        temporaryMessageIds.insert(message.id)
    }
    
    /// 段階的回答を完了し、最終回答を追加
    private func completeStepByStepResponse(with finalResponse: String) {
        // 一時的なメッセージを削除しない（履歴に残す）
        // removeTemporaryMessages()
        
        // 最終回答を追加
        let finalMessage = ChatMessage(
            text: finalResponse,
            isFromUser: false
        )
        messages.append(finalMessage)
        
        // 一時的メッセージIDをクリア（削除はしないが管理用）
        temporaryMessageIds.removeAll()
        
        // AIServiceでエラーが発生した場合はエラーメッセージを取得
        if let aiServiceError = aiService.errorMessage {
            errorMessage = aiServiceError
        }
    }
    
    /// 従来の単一回答を生成する（バックアップ用）
    private func generateSingleAIResponse(for message: String) async {
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
        temporaryMessageIds.removeAll()
    }
    
    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
        aiService.clearError()
    }
    
    /// 段階的回答モードの切り替え（設定用）
    func toggleStepByStepMode() {
        // 将来的に設定で切り替え可能にする場合
    }
} 
