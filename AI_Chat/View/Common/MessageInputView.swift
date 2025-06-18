//
//  MessageInputView.swift
//  AI_Chat
//
//  Created by Claude on 2025/06/18.
//

import SwiftUI
import Combine

struct MessageInputView: View {
    @Binding var inputText: String
    @FocusState.Binding var isInputFocused: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
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
    @State var inputText = ""
    @FocusState var isInputFocused: Bool
    
    return MessageInputView(
        inputText: $inputText,
        isInputFocused: $isInputFocused,
        onSend: { print("Send message: \(inputText)") }
    )
} 