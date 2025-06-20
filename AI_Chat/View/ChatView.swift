import SwiftUI
import Combine

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // メッセージリスト
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages, id: \.id) { message in
                                MessageRowView(message: message)
                                    .id(message.id)
                            }
                            
                            // ローディング表示
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("思考中...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        // 新しいメッセージが追加されたときにスクロール
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 入力エリア
                MessageInputView(
                    inputText: $viewModel.inputText,
                    isInputFocused: $isInputFocused,
                    onSend: viewModel.sendMessage
                )
                .disabled(viewModel.isLoading)
            }
            .navigationTitle(LocalizedStrings.aiChat)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.clearButton) {
                        viewModel.clearMessages()
                    }
                    .foregroundColor(.blue)
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
}

#Preview {
    ChatView()
} 
