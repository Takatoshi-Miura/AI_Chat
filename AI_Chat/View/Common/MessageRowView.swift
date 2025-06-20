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
    }
    
    private var userMessageView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.text)
                .padding(12)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
            
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var aiMessageView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.text)
                .padding(12)
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
            
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        MessageRowView(message: ChatMessage(text: "こんにちは！テストメッセージです。", isFromUser: true))
        MessageRowView(message: ChatMessage(text: "こんにちは！AI応答のテストメッセージです。長いテキストでも適切に表示されることを確認します。", isFromUser: false))
    }
    .padding()
} 
