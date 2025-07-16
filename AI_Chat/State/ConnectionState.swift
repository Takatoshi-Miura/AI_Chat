import Foundation
import Combine

/// 接続状態の管理を担当するクラス
@MainActor
class ConnectionState: ObservableObject {
    @Published var isConnecting: Bool = false
    @Published var connectionStatus: String = "MCPツール: 未接続"
    @Published var isAuthenticated: Bool = false
    @Published var showServerDetails: Bool = false
    @Published var lastConnectionError: String?
    
    /// 接続中状態を設定
    func setConnecting(_ connecting: Bool) {
        isConnecting = connecting
    }
    
    /// 接続ステータスを更新
    func updateConnectionStatus(_ status: String) {
        connectionStatus = status
    }
    
    /// 認証状態を設定
    func setAuthenticated(_ authenticated: Bool) {
        isAuthenticated = authenticated
    }
    
    /// サーバー詳細表示を切り替え
    func toggleServerDetails() {
        showServerDetails.toggle()
    }
    
    /// サーバー詳細表示を設定
    func setShowServerDetails(_ show: Bool) {
        showServerDetails = show
    }
    
    /// 接続エラーを設定
    func setConnectionError(_ error: String) {
        lastConnectionError = error
    }
    
    /// 接続エラーをクリア
    func clearConnectionError() {
        lastConnectionError = nil
    }
    
    /// 接続ステータスに基づいて状態を判定
    func isConnected() -> Bool {
        return connectionStatus.contains("接続済み") || connectionStatus.contains("利用可能")
    }
    
    /// 接続試行中かを判定
    func isAttemptingConnection() -> Bool {
        return connectionStatus.contains("接続中") || connectionStatus.contains("認証")
    }
}