import SwiftUI
import Combine

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showServerDetails = false
    
    let initializationError: String?
    
    init(initializationError: String? = nil) {
        self.initializationError = initializationError
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 複数サーバー対応ツールステータス表示
                mcpToolsStatusView
                
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
    }
    
    // MARK: - View Components
    
    private var mcpToolsStatusView: some View {
        VStack(spacing: 0) {
            HStack {
                statusIndicator
                
                Text(viewModel.mcpToolsStatus)
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
        Image(systemName: viewModel.mcpToolsStatus.contains("利用可能") || viewModel.mcpToolsStatus.contains("接続済み") ? "checkmark.circle.fill" : 
                         viewModel.mcpToolsStatus.contains("接続中") ? "arrow.clockwise" : "exclamationmark.triangle.fill")
            .foregroundColor(viewModel.mcpToolsStatus.contains("利用可能") || viewModel.mcpToolsStatus.contains("接続済み") ? .green : 
                           viewModel.mcpToolsStatus.contains("接続中") ? .blue : .orange)
            .imageScale(.small)
    }
    
    private var serverManagementButtons: some View {
        HStack(spacing: 8) {
            Button("全再接続") {
                Task {
                    await viewModel.retryDynamicToolsConnection()
                }
            }
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(4)
            .disabled(viewModel.mcpToolsStatus.contains("接続中"))
            
            Button(action: {
                showServerDetails.toggle()
            }) {
                Image(systemName: showServerDetails ? "chevron.up" : "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(.blue)
            .frame(minWidth: 30)
            .padding(.horizontal, 4)
        }
    }
    
    private var serverDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("サーバー接続状況")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ForEach(viewModel.getServerConnectionStatus(), id: \.url) { server in
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
                                await viewModel.retryServerConnection(server.url)
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
                                await viewModel.disconnectFromServer(server.url)
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
                        await viewModel.disconnectFromAllServers()
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(6)
                
                Spacer()
                
                Text("\(viewModel.getConnectionDetails().connected.count)/\(viewModel.getConnectionDetails().totalServers) サーバー接続済み")
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
