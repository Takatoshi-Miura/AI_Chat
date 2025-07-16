import SwiftUI

/// OAuth認証状態を表示・管理するView
struct OAuthView: View {
    @ObservedObject private var oauthService = OAuthService.shared
    @State private var showingAuthView = false
    @State private var selectedServerURL: URL?
    
    // 認証対象のサーバー一覧
    private let serverURLs: [URL] = [
        URL(string: "https://mcp-weather.get-weather.workers.dev")!
    ]
    
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
        }
        .sheet(isPresented: $showingAuthView) {
            if let serverURL = selectedServerURL {
                OAuthAuthenticationView(serverURL: serverURL)
            }
        }
    }
    
    // MARK: - View Components
    
    /// 認証状態の表示
    private var authenticationStatusView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: oauthService.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(oauthService.isAuthenticated ? .green : .red)
                    .font(.title2)
                
                Text(oauthService.isAuthenticated ? "認証済み" : "未認証")
                    .font(.headline)
                    .foregroundColor(oauthService.isAuthenticated ? .green : .red)
                
                Spacer()
            }
            
            if oauthService.isAuthenticated, let currentServer = oauthService.currentServerURL {
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
            if let error = oauthService.authenticationError {
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
            
            ForEach(serverURLs, id: \.self) { serverURL in
                serverRowView(serverURL: serverURL)
            }
        }
    }
    
    /// 個別サーバーの表示
    private func serverRowView(serverURL: URL) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(serverURL.host ?? "不明なサーバー")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(serverURL.absoluteString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 認証状態インジケーター
            Image(systemName: oauthService.isAuthenticated(for: serverURL) ? "checkmark.circle.fill" : "circle")
                .foregroundColor(oauthService.isAuthenticated(for: serverURL) ? .green : .gray)
            
            // 認証/ログアウトボタン
            if oauthService.isAuthenticated(for: serverURL) {
                Button("ログアウト") {
                    oauthService.logout(from: serverURL)
                }
                .foregroundColor(.red)
                .font(.caption)
            } else {
                Button("認証") {
                    selectedServerURL = serverURL
                    showingAuthView = true
                }
                .foregroundColor(.blue)
                .font(.caption)
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
                    await authenticateAllServers()
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
            .disabled(oauthService.isAuthenticating)
            
            // 全サーバーログアウトボタン
            Button(action: {
                oauthService.logoutFromAllServers()
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
            .disabled(!oauthService.isAuthenticated)
        }
    }
    
    // MARK: - Private Methods
    
    /// 全サーバーの認証を実行
    private func authenticateAllServers() async {
        for serverURL in serverURLs {
            if !oauthService.isAuthenticated(for: serverURL) {
                selectedServerURL = serverURL
                showingAuthView = true
                break
            }
        }
    }
}

/// OAuth認証管理のコンパクト表示View
struct OAuthStatusCompactView: View {
    @ObservedObject private var oauthService = OAuthService.shared
    @State private var showingOAuthView = false
    
    var body: some View {
        Button(action: {
            showingOAuthView = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: oauthService.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(oauthService.isAuthenticated ? .green : .red)
                    .font(.caption2)
                    .imageScale(.small)
                
                Text(oauthService.isAuthenticated ? "認証済み" : "未認証")
                    .font(.caption2)
                    .foregroundColor(oauthService.isAuthenticated ? .green : .red)
                    .lineLimit(1)
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .imageScale(.small)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(4)
            .frame(height: 24) // 他のボタンと高さを統一
        }
        .buttonStyle(PlainButtonStyle()) // ボタンのデフォルトスタイルを無効化
        .sheet(isPresented: $showingOAuthView) {
            OAuthView()
        }
    }
}

#Preview {
    OAuthView()
}

#Preview("Compact") {
    OAuthStatusCompactView()
} 