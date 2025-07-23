import Foundation
import Combine

/// MCP接続の管理と状態維持を担当するService
protocol MCPConnectionServiceProtocol {
    /// 複数のMCPサーバーに接続
    func connectToAllServers() async
    
    /// 特定のサーバーに再接続
    func retryServerConnection(_ serverURL: URL) async
    
    /// 特定のサーバーから切断
    func disconnectFromServer(_ serverURL: URL) async
    
    /// 全サーバーから切断
    func disconnectFromAllServers() async
    
    /// 利用可能なツールの情報を取得
    func getAvailableTools() -> [(name: String, description: String)]
    
    /// 接続状況文字列を取得
    func getConnectionStatusString() -> String
}

@MainActor
class MCPConnectionService: MCPConnectionServiceProtocol, ObservableObject {
    @Published private(set) var connectionStatus: String = "MCPツール: 未接続"
    
    private let aiService: AIService
    private let connectionRepository: MCPConnectionRepository
    private let authenticationService: AuthenticationServiceProtocol
    
    init(
        aiService: AIService,
        connectionRepository: MCPConnectionRepository,
        authenticationService: AuthenticationServiceProtocol
    ) {
        self.aiService = aiService
        self.connectionRepository = connectionRepository
        self.authenticationService = authenticationService
    }
    
    func connectToAllServers() async {
        connectionStatus = "MCPツール: 接続中..."
        connectionRepository.clearAllConnections()
        
        await aiService.disconnectAllServers()
        
        var allAvailableTools: [(name: String, description: String)] = []
        var connectionResults: [String] = []
        
        await withTaskGroup(of: (serverName: String, result: Result<[(name: String, description: String)], Error>).self) { group in
            
            for serverURL in connectionRepository.mcpServerURLs {
                let serverName = extractServerName(from: serverURL)
                
                group.addTask { [weak self] in
                    do {
                        // まず保存されたトークンで接続を試行
                        if await self?.aiService.connectWithStoredToken(serverURL: serverURL) == true {
                            let serverTools = await self?.aiService.getAvailableDynamicTools() ?? []
                            return (serverName: serverName, result: .success(serverTools))
                        } else {
                            // 保存されたトークンが無効または存在しない場合は新しい認証を実行
                            try await self?.aiService.connectWithAuthAndUpdateTools(serverURL: serverURL)
                            let serverTools = await self?.aiService.getAvailableDynamicTools() ?? []
                            return (serverName: serverName, result: .success(serverTools))
                        }
                    } catch {
                        return (serverName: serverName, result: .failure(error))
                    }
                }
            }
            
            for await taskResult in group {
                switch taskResult.result {
                case .success(let serverTools):
                    allAvailableTools.append(contentsOf: serverTools)
                    connectionRepository.markServerAsConnected(taskResult.serverName)
                    connectionResults.append("✅ \(taskResult.serverName): \(serverTools.count)個のツール")
                    
                    MCPStepNotificationService.shared.notifyStep("✅ \(taskResult.serverName) に認証・接続成功")
                    
                case .failure(let error):
                    connectionRepository.markServerAsFailed(taskResult.serverName)
                    connectionResults.append("❌ \(taskResult.serverName): 認証・接続エラー")
                    
                    MCPStepNotificationService.shared.notifyStep("❌ \(taskResult.serverName) 認証・接続エラー: \(error.localizedDescription)")
                }
                
                updateConnectionStatusString()
            }
        }
    }
    
    func retryServerConnection(_ serverURL: URL) async {
        let serverName = extractServerName(from: serverURL)
        connectionStatus = "MCPツール: \(serverName) に再認証・接続中..."
        
        connectionRepository.clearServerStatus(serverName)
        await aiService.disconnectFromServer(serverURL)
        
        do {
            if await aiService.connectWithStoredToken(serverURL: serverURL) {
                connectionRepository.markServerAsConnected(serverName)
                MCPStepNotificationService.shared.notifyStep("✅ \(serverName) への再接続が成功しました")
            } else {
                try await aiService.connectWithAuthAndUpdateTools(serverURL: serverURL)
                connectionRepository.markServerAsConnected(serverName)
                MCPStepNotificationService.shared.notifyStep("✅ \(serverName) への再認証・接続が成功しました")
            }
        } catch {
            connectionRepository.markServerAsFailed(serverName)
            MCPStepNotificationService.shared.notifyStep("❌ \(serverName) への再認証・接続に失敗: \(error.localizedDescription)")
        }
        
        updateConnectionStatusString()
    }
    
    func disconnectFromServer(_ serverURL: URL) async {
        let serverName = extractServerName(from: serverURL)
        
        await aiService.disconnectFromServer(serverURL)
        connectionRepository.clearServerStatus(serverName)
        
        updateConnectionStatusString()
        MCPStepNotificationService.shared.notifyStep("\(serverName) から切断しました")
    }
    
    func disconnectFromAllServers() async {
        await aiService.disconnectAllServers()
        connectionRepository.clearAllConnections()
        connectionStatus = "MCPツール: 全サーバー切断済み"
        MCPStepNotificationService.shared.notifyStep("全MCPサーバーから切断しました")
    }
    
    func getAvailableTools() -> [(name: String, description: String)] {
        return aiService.getAvailableDynamicTools()
    }
    
    func getConnectionStatusString() -> String {
        return connectionStatus
    }
    
    // MARK: - Private Methods
    
    private func updateConnectionStatusString() {
        let stats = connectionRepository.getConnectionStatistics()
        let allTools = getAvailableTools()
        
        if stats.connected == stats.total && stats.total > 0 {
            connectionStatus = "MCPツール: 全\(stats.total)サーバー接続済み (\(allTools.count)個のツール)"
        } else if stats.connected > 0 {
            connectionStatus = "MCPツール: \(stats.connected)/\(stats.total)サーバー接続済み (\(allTools.count)個のツール)"
        } else {
            connectionStatus = "MCPツール: 全サーバー接続失敗"
        }
    }
    
    private func extractServerName(from url: URL) -> String {
        return url.host ?? "不明なサーバー"
    }
}