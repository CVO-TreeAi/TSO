import Foundation
import Combine

// MARK: - API Configuration

enum APIEnvironment {
    case development
    case staging
    case production

    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:8080/api/v1"
        case .staging:
            return "https://staging-api.treeshop.app/api/v1"
        case .production:
            return "https://api.treeshop.app/api/v1"
        }
    }
}

// MARK: - API Endpoints

enum APIEndpoint: Equatable {
    // Authentication
    case login
    case logout
    case refreshToken
    case register

    // Customers
    case customers
    case customer(id: String)

    // Proposals
    case proposals
    case proposal(id: String)
    case proposalLineItems(proposalId: String)

    // Work Orders
    case workOrders
    case workOrder(id: String)

    // Loadouts
    case loadouts
    case loadout(id: String)

    // TreeScore
    case calculateTreeScore
    case treeScoreHistory

    // Sync
    case syncData
    case syncStatus

    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .logout: return "/auth/logout"
        case .refreshToken: return "/auth/refresh"
        case .register: return "/auth/register"
        case .customers: return "/customers"
        case .customer(let id): return "/customers/\(id)"
        case .proposals: return "/proposals"
        case .proposal(let id): return "/proposals/\(id)"
        case .proposalLineItems(let proposalId): return "/proposals/\(proposalId)/items"
        case .workOrders: return "/work-orders"
        case .workOrder(let id): return "/work-orders/\(id)"
        case .loadouts: return "/loadouts"
        case .loadout(let id): return "/loadouts/\(id)"
        case .calculateTreeScore: return "/treescore/calculate"
        case .treeScoreHistory: return "/treescore/history"
        case .syncData: return "/sync/data"
        case .syncStatus: return "/sync/status"
        }
    }
}

// MARK: - HTTP Methods

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int, String?)
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case rateLimited
    case offline

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error \(code): \(message ?? "Unknown error")"
        case .unauthorized:
            return "Authentication required"
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .conflict:
            return "Data conflict"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .offline:
            return "No internet connection"
        }
    }
}

// MARK: - API Service

class APIService: ObservableObject {
    static let shared = APIService()

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let environment: APIEnvironment
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var authToken: String?
    private var refreshToken: String?
    private var cancellables = Set<AnyCancellable>()

    // Token storage keys
    private let authTokenKey = "TSO_AuthToken"
    private let refreshTokenKey = "TSO_RefreshToken"

    init(environment: APIEnvironment = .production) {
        self.environment = environment

        // Configure URLSession
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)

        // Configure JSON coders
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601

        // Load stored tokens
        loadStoredTokens()
    }

    // MARK: - Token Management

    private func loadStoredTokens() {
        if let authToken = KeychainManager.shared.get(authTokenKey) {
            self.authToken = authToken
            self.isAuthenticated = true
        }
        if let refreshToken = KeychainManager.shared.get(refreshTokenKey) {
            self.refreshToken = refreshToken
        }
    }

    private func storeTokens(authToken: String, refreshToken: String?) {
        self.authToken = authToken
        self.refreshToken = refreshToken

        KeychainManager.shared.save(authToken, forKey: authTokenKey)
        if let refreshToken = refreshToken {
            KeychainManager.shared.save(refreshToken, forKey: refreshTokenKey)
        }

        self.isAuthenticated = true
    }

    private func clearTokens() {
        self.authToken = nil
        self.refreshToken = nil

        KeychainManager.shared.delete(authTokenKey)
        KeychainManager.shared.delete(refreshTokenKey)

        self.isAuthenticated = false
        self.currentUser = nil
    }

    // MARK: - Request Building

    private func buildRequest(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil
    ) -> URLRequest? {
        var urlComponents = URLComponents(string: environment.baseURL + endpoint.path)
        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add auth token if available
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body

        return request
    }

    // MARK: - Generic Request Function

    func request<T: Decodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        responseType: T.Type
    ) async throws -> T {
        // Check connectivity
        guard NetworkMonitor.shared.isConnected else {
            throw APIError.offline
        }

        // Encode body if provided
        var bodyData: Data?
        if let body = body {
            bodyData = try encoder.encode(body)
        }

        // Build request
        guard let request = buildRequest(
            endpoint: endpoint,
            method: method,
            body: bodyData,
            queryItems: queryItems
        ) else {
            throw APIError.invalidURL
        }

        // Perform request
        do {
            let (data, response) = try await session.data(for: request)

            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.noData
            }

            // Handle status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    print("Decoding error: \(error)")
                    throw APIError.decodingError
                }

            case 401:
                // Try to refresh token
                if endpoint != .refreshToken {
                    try await refreshAuthToken()
                    // Retry original request
                    return try await self.request(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        queryItems: queryItems,
                        responseType: responseType
                    )
                } else {
                    clearTokens()
                    throw APIError.unauthorized
                }

            case 403:
                throw APIError.forbidden

            case 404:
                throw APIError.notFound

            case 409:
                throw APIError.conflict

            case 429:
                throw APIError.rateLimited

            default:
                let errorMessage = String(data: data, encoding: .utf8)
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Authentication

    func login(email: String, password: String) async throws -> User {
        struct LoginRequest: Encodable {
            let email: String
            let password: String
        }

        struct LoginResponse: Decodable {
            let user: User
            let authToken: String
            let refreshToken: String?
        }

        let loginRequest = LoginRequest(email: email, password: password)

        let response = try await request(
            endpoint: .login,
            method: .post,
            body: loginRequest,
            responseType: LoginResponse.self
        )

        storeTokens(authToken: response.authToken, refreshToken: response.refreshToken)
        self.currentUser = response.user

        return response.user
    }

    func logout() async throws {
        _ = try? await request(
            endpoint: .logout,
            method: .post,
            responseType: EmptyResponse.self
        )

        clearTokens()
    }

    func register(user: UserRegistration) async throws -> User {
        struct RegisterResponse: Decodable {
            let user: User
            let authToken: String
            let refreshToken: String?
        }

        let response = try await request(
            endpoint: .register,
            method: .post,
            body: user,
            responseType: RegisterResponse.self
        )

        storeTokens(authToken: response.authToken, refreshToken: response.refreshToken)
        self.currentUser = response.user

        return response.user
    }

    private func refreshAuthToken() async throws {
        guard let refreshToken = refreshToken else {
            throw APIError.unauthorized
        }

        struct RefreshRequest: Encodable {
            let refreshToken: String
        }

        struct RefreshResponse: Decodable {
            let authToken: String
            let refreshToken: String?
        }

        let refreshRequest = RefreshRequest(refreshToken: refreshToken)

        let response = try await request(
            endpoint: .refreshToken,
            method: .post,
            body: refreshRequest,
            responseType: RefreshResponse.self
        )

        storeTokens(authToken: response.authToken, refreshToken: response.refreshToken)
    }

    // MARK: - CRUD Operations

    func fetchCustomers() async throws -> [APICustomer] {
        return try await request(
            endpoint: .customers,
            method: .get,
            responseType: [APICustomer].self
        )
    }

    func createCustomer(_ customer: APICustomer) async throws -> APICustomer {
        return try await request(
            endpoint: .customers,
            method: .post,
            body: customer,
            responseType: APICustomer.self
        )
    }

    func updateCustomer(_ customer: APICustomer) async throws -> APICustomer {
        return try await request(
            endpoint: .customer(id: customer.id.uuidString),
            method: .put,
            body: customer,
            responseType: APICustomer.self
        )
    }

    func deleteCustomer(id: UUID) async throws {
        _ = try await request(
            endpoint: .customer(id: id.uuidString),
            method: .delete,
            responseType: EmptyResponse.self
        )
    }

    // MARK: - Proposals

    func fetchProposals() async throws -> [APIProposal] {
        return try await request(
            endpoint: .proposals,
            method: .get,
            responseType: [APIProposal].self
        )
    }

    func createProposal(_ proposal: APIProposal) async throws -> APIProposal {
        return try await request(
            endpoint: .proposals,
            method: .post,
            body: proposal,
            responseType: APIProposal.self
        )
    }

    func updateProposal(_ proposal: APIProposal) async throws -> APIProposal {
        return try await request(
            endpoint: .proposal(id: proposal.id.uuidString),
            method: .put,
            body: proposal,
            responseType: APIProposal.self
        )
    }

    // MARK: - TreeScore Calculation

    func calculateTreeScore(request: TreeScoreRequest) async throws -> APITreeScoreResult {
        return try await self.request(
            endpoint: .calculateTreeScore,
            method: .post,
            body: request,
            responseType: APITreeScoreResult.self
        )
    }

    // MARK: - Data Synchronization

    func syncData() async throws -> SyncResult {
        // Get local changes
        let localChanges = try CoreDataSyncManager.shared.getLocalChanges()

        // Send to server
        let syncResult = try await request(
            endpoint: .syncData,
            method: .post,
            body: localChanges,
            responseType: SyncResult.self
        )

        // Apply remote changes
        try CoreDataSyncManager.shared.applyRemoteChanges(syncResult)

        return syncResult
    }

    func checkSyncStatus() async throws -> SyncStatus {
        return try await request(
            endpoint: .syncStatus,
            method: .get,
            responseType: SyncStatus.self
        )
    }
}

// MARK: - Supporting Models

struct EmptyResponse: Decodable {}

struct User: Codable {
    let id: UUID
    let email: String
    let name: String
    let role: UserRole
    let permissions: [Permission]
    let createdAt: Date
    let updatedAt: Date
}

struct UserRegistration: Encodable {
    let email: String
    let password: String
    let name: String
    let companyName: String?
}

enum UserRole: String, Codable {
    case owner
    case admin
    case manager
    case crew
    case viewer
}

struct Permission: Codable {
    let resource: String
    let actions: [String]
}

struct APICustomer: Codable {
    let id: UUID
    let name: String
    let email: String?
    let phone: String?
    let address: String?
    let createdAt: Date
    let updatedAt: Date
}

struct APIProposal: Codable {
    let id: UUID
    let proposalNumber: String
    let customerId: UUID
    let totalAmount: Double
    let status: String
    let lineItems: [APILineItem]?
    let createdAt: Date
    let updatedAt: Date
}

struct APILineItem: Codable {
    let id: UUID
    let description: String
    let quantity: Int
    let unitPrice: Double
    let totalPrice: Double
}

struct TreeScoreRequest: Encodable {
    let height: Double
    let dbh: Double
    let canopySpread: Double
    let afissFactors: AFISSFactorsRequest
}

struct AFISSFactorsRequest: Encodable {
    let access: String
    let felling: String
    let infrastructure: String
    let slope: String
    let special: String
}

struct APITreeScoreResult: Decodable {
    let baseScore: Double
    let afissMultiplier: Double
    let finalScore: Double
    let estimatedHours: Double
    let priceRange: PriceRange
}

struct PriceRange: Decodable {
    let min: Double
    let max: Double
    let recommended: Double
}

struct SyncResult: Codable {
    let syncedAt: Date
    let itemsSynced: Int
    let conflicts: [SyncConflict]?
    let remoteChanges: RemoteChanges?
}

struct SyncConflict: Codable {
    let entityType: String
    let entityId: UUID
    let localValue: String
    let remoteValue: String
    let resolution: String?
}

struct RemoteChanges: Codable {
    let customers: [APICustomer]?
    let proposals: [APIProposal]?
    let workOrders: [WorkOrder]?
}

struct WorkOrder: Codable {
    let id: UUID
    let workOrderNumber: String
    let customerId: UUID
    let scheduledDate: Date
    let status: String
    let estimatedDuration: Double
}

struct SyncStatus: Decodable {
    let lastSyncedAt: Date?
    let pendingChanges: Int
    let syncRequired: Bool
}