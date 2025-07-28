import Foundation

/// MCP設定の管理を担当するService（開発者コード設定方式）
protocol MCPConfigurationServiceProtocol {
    /// 全ての設定を取得
    func getAllConfigurations() -> [MCPServerConfiguration]
    
    /// 有効な設定のみを取得
    func getEnabledConfigurations() -> [MCPServerConfiguration]
    
    /// 指定したURLの設定を取得
    func getConfiguration(for serverURL: URL) -> MCPServerConfiguration?
}

class MCPConfigurationService: MCPConfigurationServiceProtocol {
    /// 開発者が直接定義するMCP設定一覧
    /// ここに新しいMCPサーバー設定を追加してください
    private let configurations: [MCPServerConfiguration] = [
        // 新しいMCPサーバー設定をここに追加
    ]
    
    // MARK: - Public Methods
    
    func getAllConfigurations() -> [MCPServerConfiguration] {
        return configurations
    }
    
    func getEnabledConfigurations() -> [MCPServerConfiguration] {
        return configurations.filter { $0.isEnabled }
    }
    
    func getConfiguration(for serverURL: URL) -> MCPServerConfiguration? {
        return configurations.first { $0.serverURL == serverURL }
    }
}
