import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRegistration = false
    @State private var useBiometric = false

    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Logo and Title
                        VStack(spacing: 20) {
                            Image(systemName: "tree.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                                .shadow(radius: 10)

                            Text("TreeShop")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Operations Management")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 50)

                        // Login Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Email", systemImage: "envelope.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(focusedField == .email ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .email)
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Password", systemImage: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(focusedField == .password ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                            }

                            // Forgot Password
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    // TODO: Implement forgot password
                                }
                                .font(.caption)
                                .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal)

                        // Login Buttons
                        VStack(spacing: 15) {
                            // Email Login Button
                            Button(action: performLogin) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)

                            // Biometric Login Button
                            if BiometricAuthManager.shared.isBiometricAvailable {
                                Button(action: performBiometricLogin) {
                                    HStack {
                                        Image(systemName: biometricIcon)
                                        Text("Sign in with \(biometricText)")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.green, lineWidth: 1)
                                    )
                                    .foregroundColor(.green)
                                    .cornerRadius(10)
                                }
                            }

                            // Divider
                            HStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("OR")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .padding(.vertical, 5)

                            // Register Button
                            Button(action: { showRegistration = true }) {
                                HStack {
                                    Text("New to TreeShop?")
                                        .foregroundColor(.secondary)
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }

                            // Demo Mode Button
                            Button(action: loginAsDemo) {
                                Text("Continue with Demo Mode")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showRegistration) {
                RegistrationView()
            }
        }
    }

    private var biometricIcon: String {
        BiometricAuthManager.shared.biometricType == .faceID ? "faceid" : "touchid"
    }

    private var biometricText: String {
        BiometricAuthManager.shared.biometricType == .faceID ? "Face ID" : "Touch ID"
    }

    private func performLogin() {
        isLoading = true
        focusedField = nil

        Task {
            do {
                _ = try await APIService.shared.login(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    authManager.isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func performBiometricLogin() {
        Task {
            let result = await BiometricAuthManager.shared.authenticate(reason: "Sign in to TreeShop")

            switch result {
            case .success(true):
                // Try to use stored credentials
                if let storedEmail = KeychainManager.shared.get("lastEmail"),
                   let storedPassword = KeychainManager.shared.get("lastPassword") {
                    email = storedEmail
                    password = storedPassword
                    performLogin()
                } else {
                    await MainActor.run {
                        errorMessage = "Please sign in with email first to enable biometric login"
                        showError = true
                    }
                }
            case .failure(let error):
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            default:
                break
            }
        }
    }

    private func loginAsDemo() {
        authManager.loginAsDemo()
    }
}

struct RegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthenticationManager.shared

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var companyName = ""
    @State private var acceptTerms = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    @State private var passwordStrength: PasswordStrength = .weak
    @State private var passwordErrors: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Company Name (Optional)", text: $companyName)
                        .textContentType(.organizationName)
                }

                Section {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .onChange(of: password) { _ in
                            validatePassword()
                        }

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)

                    if !password.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Password Strength:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(passwordStrength.description)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(strengthColor)
                            }

                            if !passwordErrors.isEmpty {
                                ForEach(passwordErrors, id: \.self) { error in
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                        Text(error)
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    Toggle(isOn: $acceptTerms) {
                        Text("I accept the Terms of Service and Privacy Policy")
                            .font(.caption)
                    }
                }

                Section {
                    Button(action: performRegistration) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                Text("Creating Account...")
                            }
                        } else {
                            Text("Create Account")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        SecurityValidator.shared.validateEmail(email) &&
        !password.isEmpty &&
        password == confirmPassword &&
        passwordStrength != .weak &&
        acceptTerms
    }

    private var strengthColor: Color {
        switch passwordStrength {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .yellow
        case .veryStrong: return .green
        }
    }

    private func validatePassword() {
        let result = SecurityValidator.shared.validatePassword(password)
        passwordStrength = result.strength
        passwordErrors = result.errors
    }

    private func performRegistration() {
        isLoading = true

        Task {
            do {
                let registration = UserRegistration(
                    email: email,
                    password: password,
                    name: name,
                    companyName: companyName.isEmpty ? nil : companyName
                )

                _ = try await APIService.shared.register(user: registration)

                await MainActor.run {
                    isLoading = false
                    authManager.isAuthenticated = true
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    LoginView()
}