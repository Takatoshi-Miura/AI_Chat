import Foundation
import Combine
import FoundationModels

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var mcpToolsStatus: String = "MCPツール: 未接続"
    
    private var aiService = AIService()
    private var stepByStepService: StepByStepResponseService
    private var cancellables = Set<AnyCancellable>()
    
    // 接続するMCPサーバーURL
    private let mcpServerURLs: [URL] = [
        URL(string: "https://mcp-weather.get-weather.workers.dev")!,
        // 追加可能
    ]
    
    // 接続状況を管理
    private var connectedServers: Set<String> = []
    private var failedServers: Set<String> = []
    
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
            await setupMultipleMCPServers()
        }
    }
    
    /// 複数のMCPサーバーに接続してツールを設定
    private func setupMultipleMCPServers() async {
        mcpToolsStatus = "MCPツール: 接続中..."
        connectedServers.removeAll()
        failedServers.removeAll()
        
        // 全てのツールをリセット
        await aiService.disconnectAllServers()
        
        var allAvailableTools: [(name: String, description: String)] = []
        var connectionResults: [String] = []
        
        // 複数サーバーに並列接続
        await withTaskGroup(of: (serverName: String, result: Result<[(name: String, description: String)], Error>).self) { group in
            
            for serverURL in mcpServerURLs {
                let serverName = extractServerName(from: serverURL)
                
                group.addTask { [weak self] in
                    do {
                        // 各サーバーに並列接続
                        try await self?.aiService.connectAndUpdateTools(serverURL: serverURL)
                        let serverTools = await self?.aiService.getAvailableDynamicTools() ?? []
                        return (serverName: serverName, result: .success(serverTools))
                    } catch {
                        return (serverName: serverName, result: .failure(error))
                    }
                }
            }
            
            // 各接続結果を収集
            for await taskResult in group {
                switch taskResult.result {
                case .success(let serverTools):
                    allAvailableTools.append(contentsOf: serverTools)
                    connectedServers.insert(taskResult.serverName)
                    connectionResults.append("✅ \(taskResult.serverName): \(serverTools.count)個のツール")
                    
                    MCPStepNotificationService.shared.notifyStep("✅ \(taskResult.serverName) に接続成功")
                    
                case .failure(let error):
                    failedServers.insert(taskResult.serverName)
                    connectionResults.append("❌ \(taskResult.serverName): 接続エラー")
                    
                    MCPStepNotificationService.shared.notifyStep("❌ \(taskResult.serverName) 接続エラー: \(error.localizedDescription)")
                }
                
                // 進行状況を更新
                let totalServers = mcpServerURLs.count
                let completedServers = connectedServers.count + failedServers.count
                mcpToolsStatus = "MCPツール: 接続中... (\(completedServers)/\(totalServers))"
            }
        }
        
        // 接続結果を更新
        updateConnectionStatus(allTools: allAvailableTools, results: connectionResults)
        
        // 利用可能なツールの情報をメッセージに追加
        if !allAvailableTools.isEmpty {
            addToolsAvailabilityMessage(tools: allAvailableTools)
        } else if !failedServers.isEmpty {
            addConnectionErrorMessage()
        }
    }
    
    /// 接続状況を更新
    private func updateConnectionStatus(allTools: [(name: String, description: String)], results: [String]) {
        let totalServers = mcpServerURLs.count
        let connectedCount = connectedServers.count
        _ = failedServers.count
        
        if connectedCount == totalServers {
            // 全サーバー接続成功
            mcpToolsStatus = "MCPツール: 全\(totalServers)サーバー接続済み (\(allTools.count)個のツール)"
        } else if connectedCount > 0 {
            // 一部サーバー接続成功
            mcpToolsStatus = "MCPツール: \(connectedCount)/\(totalServers)サーバー接続済み (\(allTools.count)個のツール)"
        } else {
            // 全サーバー接続失敗
            mcpToolsStatus = "MCPツール: 全サーバー接続失敗"
        }
    }
    
    /// 利用可能なツールの情報をメッセージに追加
    private func addToolsAvailabilityMessage(tools: [(name: String, description: String)]) {
        var message = "MCPツールが利用可能です:\n"
        
        // サーバー別の接続状況
        message += "\n接続状況:\n"
        for serverName in connectedServers {
            message += "✅ \(serverName)\n"
        }
        for serverName in failedServers {
            message += "❌ \(serverName) (接続失敗)\n"
        }
        
        // 利用可能なツール一覧
        message += "\n利用可能なツール (\(tools.count)個):\n"
        for tool in tools {
            message += "・\(tool.name): \(tool.description)\n"
        }
        
        messages.append(ChatMessage(text: message, isFromUser: false))
    }
    
    /// 接続エラーメッセージを追加
    private func addConnectionErrorMessage() {
        let errorMessage = "⚠️ 全てのMCPサーバーへの接続に失敗しました。基本機能は利用可能です。\n\n接続を試行したサーバー:\n\(mcpServerURLs.map { "・\(extractServerName(from: $0))" }.joined(separator: "\n"))"
        messages.append(ChatMessage(text: errorMessage, isFromUser: false))
    }
    
    /// URLからサーバー名を抽出
    private func extractServerName(from url: URL) -> String {
        let host = url.host ?? "不明なサーバー"
        return host
    }
    
    /// 全てのMCPサーバーとの再接続を試行
    func retryDynamicToolsConnection() {
        Task {
            await setupMultipleMCPServers()
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
    
    // MARK: - Server Management
    
    /// 特定のサーバーとの再接続を試行
    func retryServerConnection(_ serverURL: URL) async {
        let serverName = extractServerName(from: serverURL)
        mcpToolsStatus = "MCPツール: \(serverName) に再接続中..."
        
        // 失敗リストから削除し、まず既存の接続を切断
        failedServers.remove(serverName)
        connectedServers.remove(serverName)
        await aiService.disconnectFromServer(serverURL)
        
        do {
            try await aiService.connectAndUpdateTools(serverURL: serverURL)
            connectedServers.insert(serverName)
            
            let allTools = aiService.getAvailableDynamicTools()
            updateConnectionStatus(allTools: allTools, results: [])
            
            MCPStepNotificationService.shared.notifyStep("✅ \(serverName) への再接続が成功しました")
        } catch {
            failedServers.insert(serverName)
            mcpToolsStatus = "MCPツール: \(serverName) 再接続失敗"
            
            MCPStepNotificationService.shared.notifyStep("❌ \(serverName) への再接続に失敗: \(error.localizedDescription)")
        }
    }
    
    /// 特定のサーバーから切断
    func disconnectFromServer(_ serverURL: URL) async {
        let serverName = extractServerName(from: serverURL)
        
        await aiService.disconnectFromServer(serverURL)
        connectedServers.remove(serverName)
        
        let allTools = aiService.getAvailableDynamicTools()
        updateConnectionStatus(allTools: allTools, results: [])
        
        MCPStepNotificationService.shared.notifyStep("\(serverName) から切断しました")
    }
    
    /// 全サーバーから切断
    func disconnectFromAllServers() async {
        await aiService.disconnectAllServers()
        connectedServers.removeAll()
        failedServers.removeAll()
        mcpToolsStatus = "MCPツール: 全サーバー切断済み"
        MCPStepNotificationService.shared.notifyStep("全MCPサーバーから切断しました")
    }
    
    // MARK: - Debug & Configuration
    
    /// 接続状況の詳細を取得（デバッグ用）
    func getConnectionDetails() -> (connected: [String], failed: [String], totalServers: Int) {
        return (Array(connectedServers), Array(failedServers), mcpServerURLs.count)
    }
    
    /// 設定されているサーバーURL一覧を取得
    func getConfiguredServers() -> [URL] {
        return mcpServerURLs
    }
    
    /// サーバー別の接続状況を取得
    func getServerConnectionStatus() -> [(serverName: String, isConnected: Bool, url: URL)] {
        return mcpServerURLs.map { url in
            let serverName = extractServerName(from: url)
            let isConnected = connectedServers.contains(serverName)
            return (serverName: serverName, isConnected: isConnected, url: url)
        }
    }
} 
