import SwiftUI

struct MessageRowView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                userMessageView
            } else {
                aiMessageView
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.2), value: message.text)
    }
    
    private var userMessageView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            VStack(alignment: .trailing, spacing: 8) {
                // 画像表示
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 150)
                        .cornerRadius(12)
                }
                
                // テキストメッセージ（空でない場合のみ表示）
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .textSelection(.enabled)
                }
            }
            
            Text(formatTimestamp(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var aiMessageView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                // AIアバター
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("AI")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    // 画像表示
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200, maxHeight: 150)
                            .cornerRadius(12)
                    }
                    
                    // テキストメッセージ（空でない場合のみ表示）
                    if !message.text.isEmpty {
                        Text(message.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(18)
                            .textSelection(.enabled)
                    }
                }
            }
            
            Text(formatTimestamp(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.leading, 40)
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageRowView(message: ChatMessage(text: "こんにちは！", isFromUser: true))
        MessageRowView(message: ChatMessage(text: "こんにちは！何かお手伝いできることはありますか？", isFromUser: false))
        MessageRowView(message: ChatMessage(text: "🔗 MCP サーバーへの接続を開始しています...", isFromUser: false))
        MessageRowView(message: ChatMessage(text: "最終的な回答です。", isFromUser: false))
    }
    .padding()
} 
