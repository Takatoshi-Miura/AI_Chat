import SwiftUI
import Combine
import PhotosUI

struct MessageInputView: View {
    @Binding var inputText: String
    @FocusState.Binding var isInputFocused: Bool
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 選択された画像のプレビュー
            if let selectedImage = selectedImage {
                HStack {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 100)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Button(action: clearSelectedImage) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                // 画像選択ボタン (PhotosPicker)
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
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
        }
        .background(Color(.systemBackground))
    }
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil
    }
    
    private func sendMessage() {
        guard canSend else { return }
        onSend()
        isInputFocused = false
    }
    
    private func clearSelectedImage() {
        selectedImage = nil
        selectedPhotoItem = nil
    }
}

#Preview {
    @Previewable @State var inputText = ""
    @Previewable @State var selectedPhotoItem: PhotosPickerItem? = nil
    @Previewable @State var selectedImage: UIImage? = nil
    @FocusState var isInputFocused: Bool
    
    return MessageInputView(
        inputText: $inputText,
        isInputFocused: $isInputFocused,
        selectedPhotoItem: $selectedPhotoItem,
        selectedImage: $selectedImage,
        onSend: { print("Send message: \(inputText)") }
    )
} 
