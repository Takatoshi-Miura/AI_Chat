import Foundation
import Combine

/// MCP接続状態の管理を担当するViewModel
@MainActor
class MCPConnectionViewModel: ObservableObject {
    @Published var connectionStatus: String = "MCPツール: 未接続"
    @Published var showServerDetails: Bool = false
    @Published var isConnecting: Bool = false
    
    private let mcpConnectionService: MCPConnectionServiceProtocol
    private let connectionRepository: MCPConnectionRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(
        mcpConnectionService: MCPConnectionServiceProtocol,
        connectionRepository: MCPConnectionRepository
    ) {
        self.mcpConnectionService = mcpConnectionService
        self.connectionRepository = connectionRepository
        
        setupObservers()
        initializeMCPTools()
    }
    
    // MARK: - Public Methods
    
    /// 全MCPサーバーとの接続を試行
    func retryAllConnections() {
        Task {
            isConnecting = true
            await mcpConnectionService.connectToAllServers()
            isConnecting = false
        }
    }
    
    /// 特定のサーバーとの再接続を試行
    func retryServerConnection(_ serverURL: URL) async {
        await mcpConnectionService.retryServerConnection(serverURL)
    }
    
    /// 特定のサーバーから切断
    func disconnectFromServer(_ serverURL: URL) async {
        await mcpConnectionService.disconnectFromServer(serverURL)
    }
    
    /// 全サーバーから切断
    func disconnectFromAllServers() async {
        await mcpConnectionService.disconnectFromAllServers()
    }
    
    /// サーバー詳細表示を切り替え
    func toggleServerDetails() {
        showServerDetails.toggle()
    }
    
    /// 利用可能なツールの一覧を取得
    func getAvailableTools() -> [(name: String, description: String)] {
        return mcpConnectionService.getAvailableTools()
    }
    
    /// 接続統計を取得
    func getConnectionStatistics() -> (connected: Int, failed: Int, total: Int) {
        return connectionRepository.getConnectionStatistics()
    }
    
    /// サーバー別の接続状況を取得
    func getServerConnectionStatus() -> [(serverName: String, isConnected: Bool, url: URL)] {
        return connectionRepository.getServerConnectionStatus()
    }
    
    /// 接続状況のインジケーター用アイコン名を取得
    func getStatusIconName() -> String {
        if connectionStatus.contains("利用可能") || connectionStatus.contains("接続済み") {
            return "checkmark.circle.fill"
        } else if connectionStatus.contains("接続中") {
            return "arrow.clockwise"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    /// 接続状況のインジケーター用カラーを取得
    func getStatusColor() -> String {
        if connectionStatus.contains("利用可能") || connectionStatus.contains("接続済み") {
            return "green"
        } else if connectionStatus.contains("接続中") {
            return "blue"
        } else {
            return "orange"
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // MCPConnectionServiceの状態変更を監視
        if let service = mcpConnectionService as? MCPConnectionService {
            service.$connectionStatus
                .receive(on: DispatchQueue.main)
                .assign(to: \.connectionStatus, on: self)
                .store(in: &cancellables)
        }
    }
    
    private func initializeMCPTools() {
        Task {
            retryAllConnections()
        }
    }
    
    /// ツール利用可能メッセージを生成
    func generateToolsAvailabilityMessage() -> String {
        let tools = getAvailableTools()
        let stats = getConnectionStatistics()
        
        if tools.isEmpty {
            return "⚠️ 全てのMCPサーバーへの接続に失敗しました。基本機能は利用可能です。"
        }
        
        var message = "MCPツールが利用可能です:\n"
        
        // 接続状況
        message += "\n接続状況:\n"
        let serverStatus = getServerConnectionStatus()
        for server in serverStatus {
            let status = server.isConnected ? "✅" : "❌"
            message += "\(status) \(server.serverName)\n"
        }
        
        // 利用可能なツール一覧
        message += "\n利用可能なツール (\(tools.count)個):\n"
        for tool in tools {
            message += "・\(tool.name): \(tool.description)\n"
        }
        
        return message
    }
}