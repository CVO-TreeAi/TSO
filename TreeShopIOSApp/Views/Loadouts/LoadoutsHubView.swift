import SwiftUI

struct LoadoutsHubView: View {
    @State private var selectedTab = 0

    var body: some View {
        LoadoutSystemContainer()
    }
}

struct LoadoutSystemContainer: View {
    @StateObject private var equipmentManager = EquipmentManager()
    @StateObject private var employeeManager = EmployeeManager()
    @StateObject private var loadoutManager: LoadoutManager

    init() {
        let equipment = EquipmentManager()
        let employee = EmployeeManager()
        let loadout = LoadoutManager(
            equipmentManager: equipment,
            employeeManager: employee
        )

        _equipmentManager = StateObject(wrappedValue: equipment)
        _employeeManager = StateObject(wrappedValue: employee)
        _loadoutManager = StateObject(wrappedValue: loadout)
    }

    var body: some View {
        TabView {
            LoadoutManagerView()
                .environmentObject(equipmentManager)
                .environmentObject(employeeManager)
                .environmentObject(loadoutManager)
                .tabItem {
                    Label("Loadouts", systemImage: "list.bullet.rectangle")
                }
                .tag(0)

            EquipmentDirectoryView()
                .environmentObject(equipmentManager)
                .tabItem {
                    Label("Equipment", systemImage: "wrench.and.screwdriver")
                }
                .tag(1)

            EmployeeDirectoryView()
                .environmentObject(employeeManager)
                .tabItem {
                    Label("Employees", systemImage: "person.2")
                }
                .tag(2)
        }
        .navigationTitle("Loadout System")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ViewModel to manage all loadout system dependencies
class LoadoutSystemViewModel: ObservableObject {
    let equipmentManager: EquipmentManager
    let employeeManager: EmployeeManager
    let loadoutManager: LoadoutManager

    init() {
        self.equipmentManager = EquipmentManager()
        self.employeeManager = EmployeeManager()
        self.loadoutManager = LoadoutManager(
            equipmentManager: equipmentManager,
            employeeManager: employeeManager
        )
    }
}

struct LoadoutsQuickAccessCard: View {
    var body: some View {
        NavigationLink(destination: LoadoutsHubView()) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("LOADOUTS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("Manage Crews")
                            .font(.headline)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Equipment + Employees")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Calculate hourly costs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.orange.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
        }
    }
}