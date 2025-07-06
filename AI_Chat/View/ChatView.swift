import SwiftUI
import Combine

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // メッセージリスト
                messageListView
                
                Divider()
                
                // 入力エリア
                inputAreaView
            }
            .navigationTitle(LocalizedStrings.aiChat)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    clearButton
                }
            }
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
            Button("再試行") {
                viewModel.clearError()
                if !viewModel.inputText.isEmpty {
                    viewModel.sendMessage()
                }
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - View Components
    
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
