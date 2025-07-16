import Foundation

/// ViewModelの生成と依存関係の注入を管理するFactory
@MainActor
class ViewModelFactory {
    private let serviceContainer: ServiceContainer
    
    init(serviceContainer: ServiceContainer? = nil) {
        self.serviceContainer = serviceContainer ?? ServiceContainer.shared
    }
    
    /// ChatViewModelを作成
    func createChatViewModel() -> ChatViewModel {
        return ChatViewModel(
            chatRepository: serviceContainer.chatRepository,
            chatService: serviceContainer.chatService
        )
    }
    
    /// MCPConnectionViewModelを作成
    func createMCPConnectionViewModel() -> MCPConnectionViewModel {
        return MCPConnectionViewModel(
            mcpConnectionService: serviceContainer.mcpConnectionService,
            connectionRepository: serviceContainer.mcpConnectionRepository
        )
    }
    
    /// AuthenticationViewModelを作成
    func createAuthenticationViewModel() -> AuthenticationViewModel {
        return AuthenticationViewModel(
            authenticationService: serviceContainer.authenticationService
        )
    }
}