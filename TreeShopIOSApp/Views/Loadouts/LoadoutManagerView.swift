import SwiftUI

struct LoadoutManagerView: View {
    @EnvironmentObject var equipmentManager: EquipmentManager
    @EnvironmentObject var employeeManager: EmployeeManager
    @EnvironmentObject var loadoutManager: LoadoutManager

    @State private var showingCreateLoadout = false
    @State private var selectedLoadout: Loadout?
    @State private var searchText = ""

    var filteredLoadouts: [Loadout] {
        if searchText.isEmpty {
            return loadoutManager.loadouts
        } else {
            return loadoutManager.loadouts.filter { loadout in
                loadout.name.localizedCaseInsensitiveContains(searchText) ||
                loadout.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Add button
            HStack {
                Text("Loadouts")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: { showingCreateLoadout = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            .padding()

            ScrollView {
                VStack(spacing: 20) {
                    // Quick Stats
                    HStack(spacing: 16) {
                        QuickStatCard(
                            title: "Equipment",
                            value: "\(equipmentManager.equipment.count)",
                            icon: "wrench.and.screwdriver.fill",
                            color: .blue
                        )
                        QuickStatCard(
                            title: "Employees",
                            value: "\(employeeManager.employees.count)",
                            icon: "person.2.fill",
                            color: .green
                        )
                        QuickStatCard(
                            title: "Loadouts",
                            value: "\(loadoutManager.loadouts.count)",
                            icon: "list.bullet.rectangle",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Loadouts List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Active Loadouts")
                            .font(.headline)
                            .padding(.horizontal)

                        if filteredLoadouts.isEmpty {
                            EmptyStateCard(
                                icon: "plus.rectangle.on.rectangle",
                                title: "No Loadouts Yet",
                                subtitle: "Create your first loadout to combine equipment and employees"
                            )
                            .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredLoadouts) { loadout in
                                    LoadoutCard(
                                        loadout: loadout,
                                        loadoutManager: loadoutManager
                                    )
                                    .onTapGesture {
                                        selectedLoadout = loadout
                                    }
                                    .id(loadout.id)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .sheet(isPresented: $showingCreateLoadout) {
                CreateLoadoutView(
                    loadoutManager: loadoutManager,
                    equipmentManager: equipmentManager,
                    employeeManager: employeeManager
                )
            }
            .sheet(item: $selectedLoadout) { loadout in
                LoadoutDetailView(
                    loadout: loadout,
                    loadoutManager: loadoutManager,
                    equipmentManager: equipmentManager,
                    employeeManager: employeeManager
                )
            }
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct LoadoutCard: View {
    let loadout: Loadout
    @ObservedObject var loadoutManager: LoadoutManager

    var costBreakdown: LoadoutCostBreakdown {
        loadoutManager.calculateLoadoutCost(loadout)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loadout.name)
                        .font(.headline)
                    Text(loadout.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(costBreakdown.totalCost) + "/hr")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    Text("Pre-markup")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Resources Summary
            HStack(spacing: 20) {
                Label("\(loadout.equipment.count) Equipment", systemImage: "wrench.and.screwdriver")
                    .font(.caption)
                    .foregroundColor(.blue)
                Label("\(loadout.employees.count) Employees", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            // Cost Breakdown Bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    if costBreakdown.totalCost > 0 {
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: geometry.size.width * (costBreakdown.equipmentCost / costBreakdown.totalCost))
                        Rectangle()
                            .fill(Color.green.opacity(0.7))
                            .frame(width: geometry.size.width * (costBreakdown.employeeCost / costBreakdown.totalCost))
                    }
                }
            }
            .frame(height: 8)
            .background(Color(.systemFill))
            .cornerRadius(4)

            // Cost Details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Equipment")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(costBreakdown.equipmentCost) + "/hr")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                Spacer()
                VStack(alignment: .center, spacing: 4) {
                    Text("Labor")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(costBreakdown.employeeCost) + "/hr")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("With 3x Markup")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(costBreakdown.withMarkup) + "/hr")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CreateLoadoutView: View {
    @ObservedObject var loadoutManager: LoadoutManager
    @ObservedObject var equipmentManager: EquipmentManager
    @ObservedObject var employeeManager: EmployeeManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var selectedEquipment: Set<UUID> = []
    @State private var selectedEmployees: Set<UUID> = []
    @State private var equipmentUtilization: [UUID: Double] = [:]
    @State private var useTemplate = false
    @State private var selectedTemplate = ""

    var templates = [
        "Tree Removal - Standard",
        "Stump Grinding",
        "Forestry Mulching",
        "Emergency Response",
        "Pruning Crew"
    ]

    var calculatedCost: LoadoutCostBreakdown {
        var equipmentCost = 0.0
        var employeeCost = 0.0

        for equipmentId in selectedEquipment {
            if let equipment = equipmentManager.equipment.first(where: { $0.id == equipmentId }) {
                let utilization = equipmentUtilization[equipmentId] ?? 100
                equipmentCost += equipment.hourlyRate * (utilization / 100)
            }
        }

        for employeeId in selectedEmployees {
            if let employee = employeeManager.employees.first(where: { $0.id == employeeId }) {
                employeeCost += employee.trueHourlyCost
            }
        }

        return LoadoutCostBreakdown(
            equipmentCost: equipmentCost,
            employeeCost: employeeCost,
            totalCost: equipmentCost + employeeCost
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Loadout Details") {
                    TextField("Loadout Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Equipment Selection") {
                    ForEach(equipmentManager.equipment) { equipment in
                        HStack {
                            Image(systemName: selectedEquipment.contains(equipment.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedEquipment.contains(equipment.id) ? .blue : .gray)
                                .onTapGesture {
                                    if selectedEquipment.contains(equipment.id) {
                                        selectedEquipment.remove(equipment.id)
                                        equipmentUtilization.removeValue(forKey: equipment.id)
                                    } else {
                                        selectedEquipment.insert(equipment.id)
                                        equipmentUtilization[equipment.id] = 100
                                    }
                                }

                            VStack(alignment: .leading) {
                                Text(equipment.name)
                                    .font(.subheadline)
                                Text("\(formatCurrency(equipment.hourlyRate))/hr")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedEquipment.contains(equipment.id) {
                                VStack(alignment: .trailing) {
                                    Text("\(Int(equipmentUtilization[equipment.id] ?? 100))%")
                                        .font(.caption)
                                    Slider(
                                        value: Binding(
                                            get: { equipmentUtilization[equipment.id] ?? 100 },
                                            set: { equipmentUtilization[equipment.id] = $0 }
                                        ),
                                        in: 0...100,
                                        step: 10
                                    )
                                    .frame(width: 100)
                                }
                            }
                        }
                    }
                }

                Section("Employee Selection") {
                    ForEach(employeeManager.employees) { employee in
                        HStack {
                            Image(systemName: selectedEmployees.contains(employee.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedEmployees.contains(employee.id) ? .green : .gray)
                                .onTapGesture {
                                    if selectedEmployees.contains(employee.id) {
                                        selectedEmployees.remove(employee.id)
                                    } else {
                                        selectedEmployees.insert(employee.id)
                                    }
                                }

                            VStack(alignment: .leading) {
                                Text(employee.fullName)
                                    .font(.subheadline)
                                Text("\(employee.position.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("\(formatCurrency(employee.trueHourlyCost))/hr")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }

                Section("Cost Summary") {
                    HStack {
                        Text("Equipment Cost")
                        Spacer()
                        Text("\(formatCurrency(calculatedCost.equipmentCost))/hr")
                    }
                    HStack {
                        Text("Labor Cost")
                        Spacer()
                        Text("\(formatCurrency(calculatedCost.employeeCost))/hr")
                    }
                    HStack {
                        Text("Total Cost (Pre-markup)")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(formatCurrency(calculatedCost.totalCost))/hr")
                            .fontWeight(.bold)
                    }
                    HStack {
                        Text("With 3x Markup")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(formatCurrency(calculatedCost.withMarkup))/hr")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Create Loadout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLoadout()
                    }
                    .disabled(name.isEmpty || (selectedEquipment.isEmpty && selectedEmployees.isEmpty))
                }
            }
        }
    }

    private func saveLoadout() {
        let equipment = selectedEquipment.map { equipmentId in
            LoadoutEquipment(
                equipmentId: equipmentId,
                utilizationPercentage: equipmentUtilization[equipmentId] ?? 100
            )
        }

        let employees = selectedEmployees.map { employeeId in
            LoadoutEmployee(employeeId: employeeId)
        }

        let newLoadout = Loadout(
            name: name,
            description: description,
            equipment: equipment,
            employees: employees
        )

        loadoutManager.addLoadout(newLoadout)
        dismiss()
    }
}

struct LoadoutDetailView: View {
    let loadout: Loadout
    @ObservedObject var loadoutManager: LoadoutManager
    @ObservedObject var equipmentManager: EquipmentManager
    @ObservedObject var employeeManager: EmployeeManager
    @Environment(\.dismiss) var dismiss

    var costBreakdown: LoadoutCostBreakdown {
        loadoutManager.calculateLoadoutCost(loadout)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(loadout.name)
                            .font(.title2.bold())
                        Text(loadout.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    // Total Cost Card
                    VStack(spacing: 16) {
                        Text("Total Hourly Cost")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(formatCurrency(costBreakdown.totalCost) + "/hr")
                            .font(.system(size: 42, weight: .bold, design: .rounded))

                        Text("Pre-markup")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Divider()

                        HStack {
                            VStack {
                                Text("With 3x Markup")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatCurrency(costBreakdown.withMarkup) + "/hr")
                                    .font(.title3.bold())
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Cost Breakdown
                    HStack(spacing: 16) {
                        CostCategoryCard(
                            title: "Equipment",
                            amount: costBreakdown.equipmentCost,
                            percentage: costBreakdown.totalCost > 0 ? costBreakdown.equipmentCost / costBreakdown.totalCost : 0,
                            color: .blue
                        )
                        CostCategoryCard(
                            title: "Labor",
                            amount: costBreakdown.employeeCost,
                            percentage: costBreakdown.totalCost > 0 ? costBreakdown.employeeCost / costBreakdown.totalCost : 0,
                            color: .green
                        )
                    }
                    .padding(.horizontal)

                    // Equipment List
                    if !loadout.equipment.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Equipment")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(loadout.equipment) { loadoutEquipment in
                                if let equipment = equipmentManager.getEquipment(by: loadoutEquipment.equipmentId) {
                                    HStack {
                                        Image(systemName: equipment.category.icon)
                                            .foregroundColor(equipment.category.color)
                                            .frame(width: 30)

                                        VStack(alignment: .leading) {
                                            Text(equipment.name)
                                                .font(.subheadline)
                                            Text("\(Int(loadoutEquipment.utilizationPercentage))% utilization")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Text("\(formatCurrency(equipment.hourlyRate * (loadoutEquipment.utilizationPercentage / 100)))/hr")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Employee List
                    if !loadout.employees.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Employees")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(loadout.employees) { loadoutEmployee in
                                if let employee = employeeManager.getEmployee(by: loadoutEmployee.employeeId) {
                                    HStack {
                                        Image(systemName: employee.position.icon)
                                            .foregroundColor(employee.position.color)
                                            .frame(width: 30)

                                        VStack(alignment: .leading) {
                                            Text(employee.fullName)
                                                .font(.subheadline)
                                            Text(employee.position.rawValue)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Text("\(formatCurrency(employee.trueHourlyCost))/hr")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Loadout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CostCategoryCard: View {
    let title: String
    let amount: Double
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formatCurrency(amount) + "/hr")
                .font(.headline)
            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .foregroundColor(color)

            // Progress bar
            GeometryReader { geometry in
                Rectangle()
                    .fill(color.opacity(0.2))
                    .frame(height: 4)
                    .overlay(
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * percentage, height: 4),
                        alignment: .leading
                    )
            }
            .frame(height: 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}