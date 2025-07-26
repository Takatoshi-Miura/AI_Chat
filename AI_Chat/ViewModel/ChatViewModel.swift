import Foundation
import _PhotosUI_SwiftUI
import Combine
import UIKit
import PhotosUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    
    // 依存関係
    private let chatRepository: ChatRepository
    private let chatService: ChatServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties
    var messages: [ChatMessage] {
        chatRepository.getMessages()
    }
    
    var inputText: String {
        get { AppState.shared.chatState.inputText }
        set { AppState.shared.chatState.inputText = newValue }
    }
    
    init(
        chatRepository: ChatRepository,
        chatService: ChatServiceProtocol
    ) {
        self.chatRepository = chatRepository
        self.chatService = chatService
        
        setupObservers()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // ChatRepositoryの変更を監視
        chatRepository.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // ChatStateの変更を監視
        AppState.shared.chatState.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // PhotoPickerアイテムの変更を監視
        $selectedPhotoItem
            .sink { [weak self] item in
                Task {
                    await self?.loadSelectedImage(from: item)
                }
            }
            .store(in: &cancellables)
    }
    
    /// 初期化エラーをチャットに追加
    func addInitializationError(_ errorMessage: String) {
        chatRepository.addInitializationError(errorMessage)
    }
    
    /// メッセージを送信する
    func sendMessage() {
        guard AppState.shared.chatState.isInputValid() || selectedImage != nil else { return }
        
        let userMessage = inputText
        AppState.shared.chatState.clearInputText()
        
        // 画像データを準備
        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        
        // ユーザーメッセージを追加
        chatRepository.addMessage(ChatMessage(
            text: userMessage.isEmpty ? "画像を送信" : userMessage,
            isFromUser: true,
            imageData: imageData
        ))
        
        // 選択中の画像をクリア
        selectedImage = nil
        selectedPhotoItem = nil
        
        // AI応答を生成
        Task {
            await generateAIResponse(for: userMessage)
        }
    }
    
    /// AI応答を生成する
    private func generateAIResponse(for message: String) async {
        isLoading = true
        AppState.shared.chatState.setLoading(true)
        
        await chatService.sendMessage(
            message,
            onStepUpdate: { [weak self] stepMessage in
                self?.chatRepository.addMessage(stepMessage)
            },
            onFinalResponse: { [weak self] finalResponse in
                self?.completeAIResponse(with: finalResponse)
            }
        )
        
        isLoading = false
        AppState.shared.chatState.setLoading(false)
    }
 
    /// AI応答を完了し、最終回答を追加
    private func completeAIResponse(with finalResponse: String) {
        let finalMessage = ChatMessage(
            text: finalResponse,
            isFromUser: false
        )
        chatRepository.addMessage(finalMessage)
        
        // エラーがある場合はエラーメッセージをチャットに追加
        if chatService.hasError() {
            if let errorMessage = chatService.getErrorMessage() {
                let errorChatMessage = ChatMessage(text: "⚠️ \(errorMessage)", isFromUser: false)
                chatRepository.addMessage(errorChatMessage)
                chatService.clearError()
            }
        }
    }
    
    /// チャット履歴をクリア
    func clearMessages() {
        chatRepository.clearMessages()
    }
    
    // MARK: - Image Methods
    
    /// PhotoPickerアイテムから画像を読み込む
    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item = item else {
            selectedImage = nil
            return
        }
        
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                print("画像データの読み込みに失敗しました")
                return
            }
            
            guard let uiImage = UIImage(data: data) else {
                print("UIImageの作成に失敗しました")
                return
            }
            
            // 画像サイズを制限（メモリ使用量の削減）
            let resizedImage = resizeImage(uiImage, maxSize: CGSize(width: 1024, height: 1024))
            selectedImage = resizedImage
            
        } catch {
            print("画像の読み込みエラー: \(error)")
        }
    }
    
    /// 画像のリサイズ
    private func resizeImage(_ image: UIImage, maxSize: CGSize) -> UIImage {
        let size = image.size
        
        // 既に制限サイズ以下の場合はそのまま返す
        if size.width <= maxSize.width && size.height <= maxSize.height {
            return image
        }
        
        // アスペクト比を保持しながらリサイズ
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// 選択中の画像をクリア
    func clearSelectedImage() {
        selectedImage = nil
        selectedPhotoItem = nil
    }
} 
