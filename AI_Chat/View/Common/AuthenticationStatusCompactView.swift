import SwiftUI

/// 認証状態のコンパクト表示View
struct AuthenticationStatusCompactView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        Button(action: {
            viewModel.showingAuthManagementView = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.isAuthenticated ? .green : .red)
                    .font(.caption2)
                    .imageScale(.small)
                
                Text(viewModel.isAuthenticated ? "認証済み" : "未認証")
                    .font(.caption2)
                    .foregroundColor(viewModel.isAuthenticated ? .green : .red)
                    .lineLimit(1)
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .imageScale(.small)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(4)
            .frame(height: 24) // 他のボタンと高さを統一
        }
        .buttonStyle(PlainButtonStyle()) // ボタンのデフォルトスタイルを無効化
        .sheet(isPresented: $viewModel.showingAuthManagementView) {
            AuthenticationManagementView(viewModel: viewModel)
        }
    }
}