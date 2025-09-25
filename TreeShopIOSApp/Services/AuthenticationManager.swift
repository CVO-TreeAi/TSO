import SwiftUI
import Combine

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isDemoMode = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkAuthenticationStatus()
    }

    func checkAuthenticationStatus() {
        // Check if we have a valid auth token
        if let _ = KeychainManager.shared.get("TSO_AuthToken") {
            // Verify token is still valid
            Task {
                await verifyToken()
            }
        } else {
            isAuthenticated = false
        }
    }

    @MainActor
    private func verifyToken() async {
        do {
            // Try to fetch user profile with current token
            // This will trigger token refresh if needed
            let customers = try await APIService.shared.fetchCustomers()
            if !customers.isEmpty {
                isAuthenticated = true
            }
        } catch {
            // Token is invalid or expired
            isAuthenticated = false
            logout()
        }
    }

    func loginAsDemo() {
        isDemoMode = true
        isAuthenticated = true
        currentUser = User(
            id: UUID(),
            email: "demo@treeshop.app",
            name: "Demo User",
            role: .manager,
            permissions: RolePermission.managerPermissions().map { permission in
                Permission(
                    resource: permission.resource.rawValue,
                    actions: permission.actions.map { $0.rawValue }
                )
            },
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func logout() {
        KeychainManager.shared.clearAll()
        isAuthenticated = false
        currentUser = nil
        isDemoMode = false

        Task {
            try? await APIService.shared.logout()
        }
    }
}