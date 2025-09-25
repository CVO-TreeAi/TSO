import SwiftUI

@main
struct TreeShopIOSAppApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var coreDataManager = CoreDataManager()
    @StateObject private var authManager = AuthenticationManager.shared

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                AuthenticatedTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(coreDataManager)
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

struct AuthenticatedTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        TabView {
            ProposalsListView()
                .tabItem {
                    Label("Proposals", systemImage: "doc.text")
                }

            SchedulingView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }

            CustomersView()
                .tabItem {
                    Label("Customers", systemImage: "person.2")
                }

            ContentView()
                .tabItem {
                    Label("Catalog", systemImage: "tree")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}