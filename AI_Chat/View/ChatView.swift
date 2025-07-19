import SwiftUI
import Combine

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var mcpConnectionViewModel: MCPConnectionViewModel
    @StateObject private var authViewModel: AuthenticationViewModel
    @FocusState private var isInputFocused: Bool
    @State private var showServerDetails = false
    @State private var showServerInfoModal = false
    
    let initializationError: String?
    
    init(initializationError: String? = nil) {
        self.initializationError = initializationError
        
        let factory = ViewModelFactory()
        let chatVM = factory.createChatViewModel()
        let mcpVM = factory.createMCPConnectionViewModel()
        let authVM = factory.createAuthenticationViewModel()
        
        self._viewModel = StateObject(wrappedValue: chatVM)
        self._mcpConnectionViewModel = StateObject(wrappedValue: mcpVM)
        self._authViewModel = StateObject(wrappedValue: authVM)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MCP接続ステータス表示
                mcpConnectionStatusView
                
                messageListView
                
                Divider()
                
                // 入力エリア
                inputAreaView
            }
            .navigationTitle(LocalizedStrings.aiChat)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    clearButton
                }
            }
        }
        .onAppear {
            if let errorMessage = initializationError {
                viewModel.addInitializationError(errorMessage)
            }
        }
        .sheet(isPresented: $showServerInfoModal) {
            MCPServerInfoModalView(
                mcpConnectionViewModel: mcpConnectionViewModel,
                authViewModel: authViewModel,
                isPresented: $showServerInfoModal
            )
            .interactiveDismissDisabled()
        }
    }
    
    // MARK: - View Components
    
    private var mcpConnectionStatusView: some View {
        VStack(spacing: 0) {
            HStack {
                statusIndicator
                
                Text(mcpConnectionViewModel.connectionStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                serverManagementButtons
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // サーバー詳細表示
            if showServerDetails {
                serverDetailsView
            }
        }
        .background(Color.gray.opacity(0.1))
    }
    
    private var statusIndicator: some View {
        Image(systemName: mcpConnectionViewModel.getStatusIconName())
            .foregroundColor(mcpConnectionViewModel.getStatusColor() == "green" ? .green : 
                           mcpConnectionViewModel.getStatusColor() == "blue" ? .blue : .orange)
            .imageScale(.small)
    }
    
    private var serverManagementButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                showServerInfoModal = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .imageScale(.small)
                    
                    Text(LocalizedStrings.serverInfo)
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)
            .frame(height: 24) // 高さを統一
        }
        .frame(height: 24) // HStack全体の高さを統一
    }
    
    private var serverDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("サーバー接続状況")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ForEach(Array(mcpConnectionViewModel.getServerConnectionStatus().enumerated()), id: \.element.url) { index, server in
                HStack {
                    Circle()
                        .fill(server.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(server.serverName)
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !server.isConnected {
                        Button("再接続") {
                            Task {
                                await mcpConnectionViewModel.retryServerConnection(server.url)
                            }
                        }
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    } else {
                        Button("切断") {
                            Task {
                                await mcpConnectionViewModel.disconnectFromServer(server.url)
                            }
                        }
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            
            // 全サーバー管理ボタン
            HStack {
                Button("全て切断") {
                    Task {
                        await mcpConnectionViewModel.disconnectFromAllServers()
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(6)
                
                Spacer()
                
                Text("\(mcpConnectionViewModel.getConnectionStatistics().connected)/\(mcpConnectionViewModel.getConnectionStatistics().total) サーバー接続済み")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var serverDetailsButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showServerDetails.toggle()
            }
        }) {
            Image(systemName: "server.rack")
        }
        .foregroundColor(.blue)
    }
    
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages, id: \.id) { message in
                        MessageRowView(message: message)
                            .id(message.id)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.3), value: viewModel.messages.count)
            }
            .onTapGesture {
                // チャット欄をタップしたときにキーボードを閉じる
                isInputFocused = false
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.messages) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var inputAreaView: some View {
        MessageInputView(
            inputText: $viewModel.inputText,
            isInputFocused: $isInputFocused,
            onSend: viewModel.sendMessage
        )
        .disabled(viewModel.isLoading)
    }
    
    private var clearButton: some View {
        Button(LocalizedStrings.clearButton) {
            viewModel.clearMessages()
        }
        .foregroundColor(.blue)
    }
}

#Preview {
    ChatView()
} 
