import SwiftUI

@main
struct TreeShopIOSAppApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var coreDataManager = CoreDataManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(coreDataManager)
        }
    }
}