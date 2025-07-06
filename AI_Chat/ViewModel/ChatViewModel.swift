import Foundation
import Combine
import FoundationModels

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var mcpToolsStatus: String = "動的ツール: 未接続"
    
    private var aiService = AIService()
    private var stepByStepService: StepByStepResponseService
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // StepByStepResponseServiceを同じAIServiceインスタンスで初期化
        self.stepByStepService = StepByStepResponseService(aiService: aiService)
        
        // 初期化時にウェルカムメッセージを追加
        messages.append(ChatMessage(text: LocalizedStrings.welcomeMessage, isFromUser: false))
        
        // MCPツールの初期化を実行
        initializeMCPTools()
    }
    
    /// MCPツールを初期化
    private func initializeMCPTools() {
        Task {
            await setupDynamicMCPTools()
        }
    }
    
    /// 動的MCPツールを設定
    private func setupDynamicMCPTools() async {
        guard let serverURL = URL(string: "https://mcp-weather.get-weather.workers.dev") else {
            mcpToolsStatus = "MCPツール: URL設定エラー"
            return
        }
        
        do {
            mcpToolsStatus = "MCPツール: 接続中..."
            
            // MCPサーバーに接続して動的ツールを設定
            try await aiService.connectAndUpdateTools(serverURL: serverURL)
            
            let availableTools = aiService.getAvailableDynamicTools()
            if !availableTools.isEmpty {
                let toolNames = availableTools.map { $0.name }.joined(separator: ", ")
                mcpToolsStatus = "MCPツール: 利用可能 (\(toolNames))"
                
                // 利用可能なツールの情報をメッセージに追加
                let toolsMessage = "MCPツールが利用可能です:\n\(availableTools.map { "・\($0.name): \($0.description)" }.joined(separator: "\n"))"
                messages.append(ChatMessage(text: toolsMessage, isFromUser: false))
            } else {
                mcpToolsStatus = "MCPツール: ツールが見つかりませんでした"
            }
            
        } catch {
            mcpToolsStatus = "MCPツール: 接続エラー - \(error.localizedDescription)"
            
            // エラーメッセージをチャットに追加
            let errorMessage = "⚠️ MCPツールの初期化に失敗しました。基本機能は利用可能です。"
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
                    self?.messages.append(stepMessage)
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
    
    /// 段階的回答を完了し、最終回答を追加
    private func completeStepByStepResponse(with finalResponse: String) {
        let finalMessage = ChatMessage(
            text: finalResponse,
            isFromUser: false
        )
        messages.append(finalMessage)
        
        // AIServiceでエラーが発生した場合はエラーメッセージを取得
        if let aiServiceError = aiService.errorMessage {
            errorMessage = aiServiceError
        }
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
