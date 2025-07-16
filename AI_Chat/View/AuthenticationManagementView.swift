import SwiftUI

/// OAuth認証状態を表示・管理するView
struct AuthenticationManagementView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // OAuth認証状態の表示
                authenticationStatusView
                
                // サーバー一覧
                serverListView
                
                // 全体操作ボタン
                globalActionsView
                
                Spacer()
            }
            .padding()
            .navigationTitle("OAuth認証管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        viewModel.dismissAuthManagementView()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingOAuthView) {
            if let serverURL = viewModel.selectedServerURL {
                OAuthAuthenticationView(serverURL: serverURL)
            }
        }
    }
    
    // MARK: - View Components
    
    /// 認証状態の表示
    private var authenticationStatusView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: viewModel.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.isAuthenticated ? .green : .red)
                    .font(.title2)
                
                Text(viewModel.isAuthenticated ? "認証済み" : "未認証")
                    .font(.headline)
                    .foregroundColor(viewModel.isAuthenticated ? .green : .red)
                
                Spacer()
            }
            
            if viewModel.isAuthenticated, let currentServer = viewModel.currentServerURL {
                HStack {
                    Text("認証中のサーバー:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(currentServer.host ?? "不明")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
            }
            
            // エラーメッセージの表示
            if let error = viewModel.authenticationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    /// サーバー一覧の表示
    private var serverListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MCPサーバー")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(viewModel.getServerAuthenticationStatus(), id: \.serverURL) { server in
                serverRowView(server: server)
            }
        }
    }
    
    /// 個別サーバーの表示
    private func serverRowView(server: (serverURL: URL, serverName: String, isAuthenticated: Bool)) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(server.serverName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(server.serverURL.absoluteString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 認証状態インジケーター
            Image(systemName: server.isAuthenticated ? "checkmark.circle.fill" : "circle")
                .foregroundColor(server.isAuthenticated ? .green : .gray)
            
            // 認証/ログアウトボタン
            if server.isAuthenticated {
                Button("ログアウト") {
                    viewModel.logout(from: server.serverURL)
                }
                .foregroundColor(.red)
                .font(.caption)
            } else {
                Button("認証") {
                    Task {
                        await viewModel.authenticate(serverURL: server.serverURL)
                    }
                }
                .foregroundColor(.blue)
                .font(.caption)
                .disabled(viewModel.isAuthenticating)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    /// 全体操作ボタン
    private var globalActionsView: some View {
        VStack(spacing: 12) {
            // 全サーバー認証ボタン
            Button(action: {
                Task {
                    await viewModel.authenticateAllServers()
                }
            }) {
                HStack {
                    Image(systemName: "key.fill")
                    Text("全サーバー認証")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.isAuthenticating)
            
            // 全サーバーログアウトボタン
            Button(action: {
                viewModel.logoutFromAllServers()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("全サーバーログアウト")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!viewModel.isAuthenticated)
        }
    }
}