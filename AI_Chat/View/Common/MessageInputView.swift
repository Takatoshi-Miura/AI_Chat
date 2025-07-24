import SwiftUI
import Combine

struct MessageInputView: View {
    @Binding var inputText: String
    @FocusState.Binding var isInputFocused: Bool
    let onSend: () -> Void
    let onImageTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 画像選択ボタン
            Button(action: onImageTap) {
                Image(systemName: "photo")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .accessibilityLabel("画像を選択")
            
            TextField(LocalizedStrings.messagePlaceholder, text: $inputText, axis: .vertical)
                .focused($isInputFocused)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(canSend ? Color.blue : Color.gray)
                    .clipShape(Circle())
            }
            .disabled(!canSend)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendMessage() {
        guard canSend else { return }
        onSend()
        isInputFocused = false
    }
}

#Preview {
    @Previewable @State var inputText = ""
    @FocusState var isInputFocused: Bool
    
    return MessageInputView(
        inputText: $inputText,
        isInputFocused: $isInputFocused,
        onSend: { print("Send message: \(inputText)") },
        onImageTap: { print("Image tap") }
    )
} 
