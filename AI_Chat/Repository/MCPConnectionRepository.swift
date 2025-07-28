import Foundation
import Combine

/// MCP接続状態のデータ管理を担当するRepository
protocol MCPConnectionRepositoryProtocol {
    /// 接続中のサーバー一覧を取得
    func getConnectedServers() -> Set<String>
    
    /// 失敗したサーバー一覧を取得
    func getFailedServers() -> Set<String>
    
    /// サーバーを接続済みに設定
    func markServerAsConnected(_ serverName: String)
    
    /// サーバーを失敗に設定
    func markServerAsFailed(_ serverName: String)
    
    /// サーバーの接続状態をクリア
    func clearServerStatus(_ serverName: String)
    
    /// 全ての接続状態をクリア
    func clearAllConnections()
    
    /// サーバーが接続中かチェック
    func isServerConnected(_ serverName: String) -> Bool
    
    /// サーバーが失敗状態かチェック
    func isServerFailed(_ serverName: String) -> Bool
    
    /// 有効なMCPサーバーのURL一覧を取得
    var mcpServerURLs: [URL] { get }
}

@MainActor
class MCPConnectionRepository: MCPConnectionRepositoryProtocol, ObservableObject {
    @Published private(set) var connectedServers: Set<String> = []
    @Published private(set) var failedServers: Set<String> = []
    
    private let configurationService: MCPConfigurationServiceProtocol
    
    init(configurationService: MCPConfigurationServiceProtocol) {
        self.configurationService = configurationService
    }
    
    /// 有効なMCPサーバーのURL一覧を取得（設定サービスから）
    var mcpServerURLs: [URL] {
        return configurationService.getEnabledConfigurations().map { $0.serverURL }
    }
    
    func getConnectedServers() -> Set<String> {
        return connectedServers
    }
    
    func getFailedServers() -> Set<String> {
        return failedServers
    }
    
    func markServerAsConnected(_ serverName: String) {
        connectedServers.insert(serverName)
        failedServers.remove(serverName)
    }
    
    func markServerAsFailed(_ serverName: String) {
        failedServers.insert(serverName)
        connectedServers.remove(serverName)
    }
    
    func clearServerStatus(_ serverName: String) {
        connectedServers.remove(serverName)
        failedServers.remove(serverName)
    }
    
    func clearAllConnections() {
        connectedServers.removeAll()
        failedServers.removeAll()
    }
    
    func isServerConnected(_ serverName: String) -> Bool {
        return connectedServers.contains(serverName)
    }
    
    func isServerFailed(_ serverName: String) -> Bool {
        return failedServers.contains(serverName)
    }
    
    /// 接続統計を取得
    func getConnectionStatistics() -> (connected: Int, failed: Int, total: Int) {
        let totalServers = configurationService.getEnabledConfigurations().count
        return (
            connected: connectedServers.count,
            failed: failedServers.count,
            total: totalServers
        )
    }
    
    /// サーバー別の接続状況を取得
    func getServerConnectionStatus() -> [(serverName: String, isConnected: Bool, url: URL)] {
        return mcpServerURLs.map { url in
            let serverName = extractServerName(from: url)
            let isConnected = connectedServers.contains(serverName)
            return (serverName: serverName, isConnected: isConnected, url: url)
        }
    }
    
    /// URLからサーバー名を抽出
    private func extractServerName(from url: URL) -> String {
        return url.host ?? "不明なサーバー"
    }
}