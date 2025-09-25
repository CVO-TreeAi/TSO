import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var apiService = APIService.shared
    @State private var showingLogoutConfirmation = false
    @State private var showingEditProfile = false
    @State private var showingChangePassword = false
    @State private var showingNotifications = false
    @State private var biometricEnabled = false

    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                Section {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)

                            Text(authManager.currentUser?.name.prefix(2).uppercased() ?? "??")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.name ?? "User")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text(authManager.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: roleIcon)
                                    .font(.caption)
                                Text(authManager.currentUser?.role.rawValue.capitalized ?? "User")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(roleColor.opacity(0.2))
                            .foregroundColor(roleColor)
                            .cornerRadius(4)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)

                    if authManager.isDemoMode {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Demo Mode Active")
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Account Settings
                Section("Account Settings") {
                    Button(action: { showingEditProfile = true }) {
                        SettingRow(
                            icon: "person.fill",
                            title: "Edit Profile",
                            color: .blue
                        )
                    }

                    Button(action: { showingChangePassword = true }) {
                        SettingRow(
                            icon: "lock.fill",
                            title: "Change Password",
                            color: .orange
                        )
                    }

                    if BiometricAuthManager.shared.isBiometricAvailable {
                        Toggle(isOn: $biometricEnabled) {
                            HStack {
                                Image(systemName: biometricIcon)
                                    .foregroundColor(.purple)
                                    .frame(width: 30)
                                Text("Enable \(biometricText)")
                            }
                        }
                        .onChange(of: biometricEnabled) { enabled in
                            handleBiometricToggle(enabled)
                        }
                    }
                }

                // App Settings
                Section("App Settings") {
                    Button(action: { showingNotifications = true }) {
                        SettingRow(
                            icon: "bell.fill",
                            title: "Notifications",
                            value: "On",
                            color: .green
                        )
                    }

                    NavigationLink(destination: DataManagementView()) {
                        SettingRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Data & Sync",
                            color: .blue
                        )
                    }

                    NavigationLink(destination: SecuritySettingsView()) {
                        SettingRow(
                            icon: "shield.fill",
                            title: "Security & Privacy",
                            color: .indigo
                        )
                    }
                }

                // Company Settings (Admin/Owner only)
                if authManager.currentUser?.role == .owner || authManager.currentUser?.role == .admin {
                    Section("Company Settings") {
                        NavigationLink(destination: UserManagementView()) {
                            SettingRow(
                                icon: "person.2.fill",
                                title: "User Management",
                                color: .teal
                            )
                        }

                        NavigationLink(destination: BillingView()) {
                            SettingRow(
                                icon: "creditcard.fill",
                                title: "Billing & Subscription",
                                color: .purple
                            )
                        }

                        NavigationLink(destination: IntegrationsView()) {
                            SettingRow(
                                icon: "app.connected.to.app.below.fill",
                                title: "Integrations",
                                color: .orange
                            )
                        }
                    }
                }

                // Support
                Section("Support") {
                    Link(destination: URL(string: "https://treeshop.app/help")!) {
                        SettingRow(
                            icon: "questionmark.circle.fill",
                            title: "Help Center",
                            color: .blue
                        )
                    }

                    Link(destination: URL(string: "mailto:support@treeshop.app")!) {
                        SettingRow(
                            icon: "envelope.fill",
                            title: "Contact Support",
                            color: .green
                        )
                    }

                    NavigationLink(destination: AboutView()) {
                        SettingRow(
                            icon: "info.circle.fill",
                            title: "About",
                            value: "v1.0.0",
                            color: .gray
                        )
                    }
                }

                // Logout
                Section {
                    Button(action: { showingLogoutConfirmation = true }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView()
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showingLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    authManager.logout()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .onAppear {
            loadBiometricSetting()
        }
    }

    private var roleIcon: String {
        switch authManager.currentUser?.role {
        case .owner: return "crown.fill"
        case .admin: return "person.badge.shield.checkmark.fill"
        case .manager: return "person.badge.key.fill"
        case .crew: return "person.fill"
        case .viewer: return "eye.fill"
        default: return "person.fill"
        }
    }

    private var roleColor: Color {
        switch authManager.currentUser?.role {
        case .owner: return .purple
        case .admin: return .blue
        case .manager: return .green
        case .crew: return .orange
        case .viewer: return .gray
        default: return .gray
        }
    }

    private var biometricIcon: String {
        BiometricAuthManager.shared.biometricType == .faceID ? "faceid" : "touchid"
    }

    private var biometricText: String {
        BiometricAuthManager.shared.biometricType == .faceID ? "Face ID" : "Touch ID"
    }

    private func loadBiometricSetting() {
        biometricEnabled = KeychainManager.shared.get("biometricEnabled") == "true"
    }

    private func handleBiometricToggle(_ enabled: Bool) {
        if enabled {
            // Store credentials for biometric login
            if let email = authManager.currentUser?.email {
                KeychainManager.shared.save(email, forKey: "lastEmail")
                KeychainManager.shared.save("true", forKey: "biometricEnabled")
            }
        } else {
            KeychainManager.shared.delete("lastEmail")
            KeychainManager.shared.delete("lastPassword")
            KeychainManager.shared.save("false", forKey: "biometricEnabled")
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)

            Text(title)
                .foregroundColor(.primary)

            Spacer()

            if let value = value {
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// Placeholder views for navigation destinations
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: .constant(""))
                    TextField("Email", text: .constant(""))
                    TextField("Phone", text: .constant(""))
                }

                Section("Company Information") {
                    TextField("Company Name", text: .constant(""))
                    TextField("Company Address", text: .constant(""))
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

struct DataManagementView: View {
    var body: some View {
        List {
            Section("Sync Settings") {
                Toggle("Auto-sync", isOn: .constant(true))
                HStack {
                    Text("Last Synced")
                    Spacer()
                    Text("2 minutes ago")
                        .foregroundColor(.secondary)
                }
                Button("Sync Now") { }
            }

            Section("Storage") {
                HStack {
                    Text("Local Storage")
                    Spacer()
                    Text("124 MB")
                        .foregroundColor(.secondary)
                }
                Button("Clear Cache", role: .destructive) { }
            }
        }
        .navigationTitle("Data & Sync")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SecuritySettingsView: View {
    var body: some View {
        List {
            Section("Privacy") {
                Toggle("Analytics", isOn: .constant(true))
                Toggle("Crash Reports", isOn: .constant(true))
            }

            Section("Security") {
                Toggle("Require PIN on Launch", isOn: .constant(false))
                Toggle("Auto-lock", isOn: .constant(true))
            }
        }
        .navigationTitle("Security & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UserManagementView: View {
    var body: some View {
        Text("User Management")
            .navigationTitle("Users")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct BillingView: View {
    var body: some View {
        Text("Billing & Subscription")
            .navigationTitle("Billing")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct IntegrationsView: View {
    var body: some View {
        Text("Integrations")
            .navigationTitle("Integrations")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text("100")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Link("Terms of Service", destination: URL(string: "https://treeshop.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://treeshop.app/privacy")!)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
}