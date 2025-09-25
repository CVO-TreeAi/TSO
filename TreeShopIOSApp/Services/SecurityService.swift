import Foundation
import Security
import CryptoKit
import LocalAuthentication
import Network

// MARK: - Keychain Manager

class KeychainManager {
    static let shared = KeychainManager()
    private let serviceName = "com.treeshop.ios"

    private init() {}

    // MARK: - Save to Keychain

    func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete existing item if any
        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Get from Keychain

    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    // MARK: - Delete from Keychain

    @discardableResult
    func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Clear All

    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Encryption Manager

class EncryptionManager {
    static let shared = EncryptionManager()

    private init() {}

    // MARK: - AES Encryption

    func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let encrypted = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        return encrypted
    }

    func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - Key Generation

    func generateSymmetricKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }

    func deriveKey(from password: String, salt: Data) -> SymmetricKey? {
        guard let passwordData = password.data(using: .utf8) else { return nil }

        let derivedKey = PBKDF2.deriveKey(
            password: passwordData,
            salt: salt,
            iterations: 100_000,
            keyLength: 32
        )

        return SymmetricKey(data: derivedKey)
    }

    func generateSalt() -> Data {
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        return salt
    }

    // MARK: - Hashing

    func hash(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func hashString(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else { return nil }
        return hash(data)
    }

    // MARK: - Secure Data Storage

    func encryptAndStore(_ data: Data, forKey key: String, with password: String) -> Bool {
        let salt = generateSalt()
        guard let symmetricKey = deriveKey(from: password, salt: salt) else { return false }

        do {
            let encryptedData = try encrypt(data, using: symmetricKey)

            // Store encrypted data and salt
            let storageData = StorageData(encryptedData: encryptedData, salt: salt)
            let encodedData = try JSONEncoder().encode(storageData)

            return KeychainManager.shared.save(
                encodedData.base64EncodedString(),
                forKey: key
            )
        } catch {
            print("Encryption error: \(error)")
            return false
        }
    }

    func retrieveAndDecrypt(forKey key: String, with password: String) -> Data? {
        guard let base64String = KeychainManager.shared.get(key),
              let encodedData = Data(base64Encoded: base64String) else { return nil }

        do {
            let storageData = try JSONDecoder().decode(StorageData.self, from: encodedData)
            guard let symmetricKey = deriveKey(from: password, salt: storageData.salt) else { return nil }

            return try decrypt(storageData.encryptedData, using: symmetricKey)
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }
}

// MARK: - Biometric Authentication

class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    private let context = LAContext()

    private init() {}

    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    var biometricType: BiometricType {
        guard isBiometricAvailable else { return .none }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }

    func authenticate(reason: String) async -> Result<Bool, AuthenticationError> {
        guard isBiometricAvailable else {
            return .failure(.biometricNotAvailable)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return .success(success)
        } catch let error as LAError {
            return .failure(mapLAError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    private func mapLAError(_ error: LAError) -> AuthenticationError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .biometryLockout:
            return .biometricLockout
        case .biometryNotAvailable:
            return .biometricNotAvailable
        case .biometryNotEnrolled:
            return .biometricNotEnrolled
        default:
            return .unknown
        }
    }
}

// MARK: - Network Monitor

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(from: path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
}

// MARK: - Role-Based Access Control

class RBACManager {
    static let shared = RBACManager()

    private init() {}

    func hasPermission(
        user: User,
        resource: ResourceType,
        action: ActionType
    ) -> Bool {
        // Check role-based permissions
        let rolePermissions = getRolePermissions(user.role)

        if rolePermissions.contains(where: {
            $0.resource == resource && $0.actions.contains(action)
        }) {
            return true
        }

        // Check user-specific permissions
        return user.permissions.contains(where: {
            $0.resource == resource.rawValue &&
            $0.actions.contains(action.rawValue)
        })
    }

    private func getRolePermissions(_ role: UserRole) -> [RolePermission] {
        switch role {
        case .owner:
            return RolePermission.allPermissions()
        case .admin:
            return RolePermission.adminPermissions()
        case .manager:
            return RolePermission.managerPermissions()
        case .crew:
            return RolePermission.crewPermissions()
        case .viewer:
            return RolePermission.viewerPermissions()
        }
    }
}

// MARK: - Security Validator

class SecurityValidator {
    static let shared = SecurityValidator()

    private init() {}

    func validatePassword(_ password: String) -> PasswordValidationResult {
        var errors: [String] = []

        if password.count < 8 {
            errors.append("Password must be at least 8 characters long")
        }

        if !password.contains(where: { $0.isUppercase }) {
            errors.append("Password must contain at least one uppercase letter")
        }

        if !password.contains(where: { $0.isLowercase }) {
            errors.append("Password must contain at least one lowercase letter")
        }

        if !password.contains(where: { $0.isNumber }) {
            errors.append("Password must contain at least one number")
        }

        let specialCharacters = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        if !password.contains(where: { specialCharacters.contains($0) }) {
            errors.append("Password must contain at least one special character")
        }

        let strength = calculatePasswordStrength(password)

        return PasswordValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            strength: strength
        )
    }

    private func calculatePasswordStrength(_ password: String) -> PasswordStrength {
        var score = 0

        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isLowercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) { score += 1 }

        switch score {
        case 0...2: return .weak
        case 3...4: return .medium
        case 5...6: return .strong
        default: return .veryStrong
        }
    }

    func validateEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func sanitizeInput(_ input: String) -> String {
        // Remove potentially dangerous characters for SQL/NoSQL injection
        let dangerousCharacters = ["'", "\"", ";", "--", "/*", "*/", "xp_", "sp_", "0x"]
        var sanitized = input

        for char in dangerousCharacters {
            sanitized = sanitized.replacingOccurrences(of: char, with: "")
        }

        // Trim whitespace
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)

        // Limit length
        if sanitized.count > 1000 {
            sanitized = String(sanitized.prefix(1000))
        }

        return sanitized
    }
}

// MARK: - Supporting Types

enum EncryptionError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed

    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        }
    }
}

enum BiometricType {
    case none
    case faceID
    case touchID
}

enum AuthenticationError: LocalizedError {
    case biometricNotAvailable
    case biometricNotEnrolled
    case biometricLockout
    case authenticationFailed
    case userCancelled
    case userFallback
    case unknown

    var errorDescription: String? {
        switch self {
        case .biometricNotAvailable:
            return "Biometric authentication is not available"
        case .biometricNotEnrolled:
            return "No biometric data is enrolled"
        case .biometricLockout:
            return "Biometric authentication is locked"
        case .authenticationFailed:
            return "Authentication failed"
        case .userCancelled:
            return "Authentication was cancelled"
        case .userFallback:
            return "User chose to use password"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
}

enum ResourceType: String {
    case customers
    case proposals
    case workOrders
    case loadouts
    case reports
    case settings
    case users
}

enum ActionType: String {
    case create
    case read
    case update
    case delete
    case approve
    case export
}

struct RolePermission {
    let resource: ResourceType
    let actions: [ActionType]

    static func allPermissions() -> [RolePermission] {
        return ResourceType.allCases.map { resource in
            RolePermission(resource: resource, actions: ActionType.allCases)
        }
    }

    static func adminPermissions() -> [RolePermission] {
        return [
            RolePermission(resource: .customers, actions: ActionType.allCases),
            RolePermission(resource: .proposals, actions: ActionType.allCases),
            RolePermission(resource: .workOrders, actions: ActionType.allCases),
            RolePermission(resource: .loadouts, actions: ActionType.allCases),
            RolePermission(resource: .reports, actions: [.read, .export]),
            RolePermission(resource: .settings, actions: [.read, .update]),
            RolePermission(resource: .users, actions: [.read, .create, .update])
        ]
    }

    static func managerPermissions() -> [RolePermission] {
        return [
            RolePermission(resource: .customers, actions: [.read, .create, .update]),
            RolePermission(resource: .proposals, actions: [.read, .create, .update, .approve]),
            RolePermission(resource: .workOrders, actions: [.read, .create, .update]),
            RolePermission(resource: .loadouts, actions: [.read, .create, .update]),
            RolePermission(resource: .reports, actions: [.read])
        ]
    }

    static func crewPermissions() -> [RolePermission] {
        return [
            RolePermission(resource: .customers, actions: [.read]),
            RolePermission(resource: .workOrders, actions: [.read, .update]),
            RolePermission(resource: .loadouts, actions: [.read])
        ]
    }

    static func viewerPermissions() -> [RolePermission] {
        return [
            RolePermission(resource: .customers, actions: [.read]),
            RolePermission(resource: .proposals, actions: [.read]),
            RolePermission(resource: .workOrders, actions: [.read])
        ]
    }
}

struct PasswordValidationResult {
    let isValid: Bool
    let errors: [String]
    let strength: PasswordStrength
}

enum PasswordStrength {
    case weak
    case medium
    case strong
    case veryStrong

    var color: String {
        switch self {
        case .weak: return "red"
        case .medium: return "orange"
        case .strong: return "yellow"
        case .veryStrong: return "green"
        }
    }

    var description: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }
}

struct StorageData: Codable {
    let encryptedData: Data
    let salt: Data
}

// MARK: - PBKDF2 Implementation

struct PBKDF2 {
    static func deriveKey(password: Data, salt: Data, iterations: Int, keyLength: Int) -> Data {
        var derivedKey = Data(count: keyLength)

        derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            password.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: Int8.self).baseAddress!,
                        password.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress!,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress!,
                        keyLength
                    )
                }
            }
        }

        return derivedKey
    }
}

// Extension to make enums CaseIterable for convenience
extension ResourceType: CaseIterable {}
extension ActionType: CaseIterable {}

// Import CommonCrypto for PBKDF2
import CommonCrypto