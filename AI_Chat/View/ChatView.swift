import SwiftUI
import Combine

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 動的ツールステータス表示
                dynamicToolsStatusView
                
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
                    retryConnectionButton
                }
            }
        }
        .alert("エラー", isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.clearError() }
        )) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - View Components
    
    private var dynamicToolsStatusView: some View {
        HStack {
            Image(systemName: viewModel.mcpToolsStatus.contains("利用可能") ? "checkmark.circle.fill" : 
                             viewModel.mcpToolsStatus.contains("接続中") ? "arrow.clockwise" : "exclamationmark.triangle.fill")
                .foregroundColor(viewModel.mcpToolsStatus.contains("利用可能") ? .green : 
                               viewModel.mcpToolsStatus.contains("接続中") ? .blue : .orange)
            
            Text(viewModel.mcpToolsStatus)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
    }
    
    private var retryConnectionButton: some View {
        Button(action: {
            viewModel.retryDynamicToolsConnection()
        }) {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(viewModel.mcpToolsStatus.contains("接続中"))
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
