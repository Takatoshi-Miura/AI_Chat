import SwiftUI

struct MCPServerInfoModalView: View {
    @ObservedObject var mcpConnectionViewModel: MCPConnectionViewModel
    @ObservedObject var authViewModel: AuthenticationViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // ヘッダー統計情報
                headerStatsView
                
                Divider()
                
                // サーバー一覧
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(getServerInfoList().enumerated()), id: \.element.url) { index, serverInfo in
                            ServerInfoCardView(
                                serverInfo: serverInfo,
                                mcpConnectionViewModel: mcpConnectionViewModel,
                                authViewModel: authViewModel
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle(LocalizedStrings.serverInfo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.close) {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - Header Stats View
    
    private var headerStatsView: some View {
        VStack(spacing: 8) {
            HStack {
                // 接続統計
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStrings.connectionStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let connectionStats = mcpConnectionViewModel.getConnectionStatistics()
                    Text("\(connectionStats.connected)/\(connectionStats.total)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                // 認証統計
                VStack(alignment: .trailing, spacing: 4) {
                    Text(LocalizedStrings.authenticationStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let authStats = authViewModel.getAuthenticationSummary()
                    Text("\(authStats.authenticated)/\(authStats.total)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()
            }
            
            // 利用可能ツール数
            HStack {
                Text(LocalizedStrings.availableTools)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                let toolsCount = mcpConnectionViewModel.getAvailableTools().count
                Text("\(toolsCount)\(LocalizedStrings.toolsCount)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    
    private func getServerInfoList() -> [ServerInfo] {
        let connectionStatus = mcpConnectionViewModel.getServerConnectionStatus()
        let authStatus = authViewModel.getServerAuthenticationStatus()
        
        // 接続状況とOAuth認証状況を結合
        var serverInfoList: [ServerInfo] = []
        
        // 接続状況を基準にサーバー情報を作成
        for connection in connectionStatus {
            let auth = authStatus.first { $0.serverURL == connection.url }
            let serverInfo = ServerInfo(
                url: connection.url,
                name: connection.serverName,
                isConnected: connection.isConnected,
                isAuthenticated: auth?.isAuthenticated ?? false
            )
            serverInfoList.append(serverInfo)
        }
        
        // OAuth認証対象だが接続状況にないサーバーも追加
        for auth in authStatus {
            if !serverInfoList.contains(where: { $0.url == auth.serverURL }) {
                let serverInfo = ServerInfo(
                    url: auth.serverURL,
                    name: auth.serverName,
                    isConnected: false,
                    isAuthenticated: auth.isAuthenticated
                )
                serverInfoList.append(serverInfo)
            }
        }
        
        return serverInfoList
    }
}

// MARK: - Server Info Card View

struct ServerInfoCardView: View {
    let serverInfo: ServerInfo
    @ObservedObject var mcpConnectionViewModel: MCPConnectionViewModel
    @ObservedObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // サーバー名
            Text(serverInfo.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            // 接続状況と再接続ボタン
            HStack {
                // 接続状況
                HStack(spacing: 4) {
                    Circle()
                        .fill(serverInfo.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(serverInfo.isConnected ? LocalizedStrings.connected : LocalizedStrings.disconnected)
                        .font(.caption)
                        .foregroundColor(serverInfo.isConnected ? .green : .red)
                }
                
                // 再接続ボタン
                Button(LocalizedStrings.reconnect) {
                    Task {
                        await mcpConnectionViewModel.retryServerConnection(serverInfo.url)
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(6)
                .disabled(mcpConnectionViewModel.isConnecting)
                
                Spacer()
            }
            
            // 認証状況と再認証ボタン
            HStack {
                // 認証状況
                HStack(spacing: 4) {
                    Image(systemName: serverInfo.isAuthenticated ? "checkmark.shield.fill" : "xmark.shield.fill")
                        .font(.caption)
                        .foregroundColor(serverInfo.isAuthenticated ? .green : .orange)
                    
                    Text(serverInfo.isAuthenticated ? LocalizedStrings.authenticated : LocalizedStrings.notAuthenticated)
                        .font(.caption)
                        .foregroundColor(serverInfo.isAuthenticated ? .green : .orange)
                }
                
                // 再認証ボタン
                if authViewModel.serverURLs.contains(serverInfo.url) {
                    Button(LocalizedStrings.reauthenticate) {
                        Task {
                            await authViewModel.authenticate(serverURL: serverInfo.url)
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(6)
                    .disabled(authViewModel.isAuthenticating)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Server Info Model

struct ServerInfo {
    let url: URL
    let name: String
    let isConnected: Bool
    let isAuthenticated: Bool
}

#Preview {
    let configurationService = MCPConfigurationService()
    let authService = AuthenticationService(configurationService: configurationService)
    let connectionRepository = MCPConnectionRepository(configurationService: configurationService)
    let aiService = AIService()
    
    MCPServerInfoModalView(
        mcpConnectionViewModel: MCPConnectionViewModel(
            mcpConnectionService: MCPConnectionService(
                aiService: aiService,
                connectionRepository: connectionRepository,
                authenticationService: authService
            ),
            connectionRepository: connectionRepository
        ),
        authViewModel: AuthenticationViewModel(
            authenticationService: authService
        ),
        isPresented: .constant(true)
    )
}
