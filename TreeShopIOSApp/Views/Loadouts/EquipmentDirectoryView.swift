import SwiftUI

struct EquipmentDirectoryView: View {
    @EnvironmentObject var equipmentManager: EquipmentManager
    @State private var showingAddEquipment = false
    @State private var selectedEquipment: Equipment?
    @State private var searchText = ""
    @State private var selectedCategory: EquipmentCategory?

    var filteredEquipment: [Equipment] {
        let categoryFiltered = selectedCategory != nil
            ? equipmentManager.equipment.filter { $0.category == selectedCategory }
            : equipmentManager.equipment

        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { equipment in
                equipment.name.localizedCaseInsensitiveContains(searchText) ||
                equipment.manufacturer.localizedCaseInsensitiveContains(searchText) ||
                equipment.model.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Add button
            HStack {
                Text("Equipment")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: { showingAddEquipment = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            .padding()

            ScrollView {
                VStack(spacing: 20) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryFilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                color: .gray
                            ) {
                                withAnimation { selectedCategory = nil }
                            }

                            ForEach(EquipmentCategory.allCases) { category in
                                CategoryFilterChip(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    color: category.color
                                ) {
                                    withAnimation {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Equipment Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredEquipment) { equipment in
                            EquipmentCard(equipment: equipment)
                                .onTapGesture {
                                    selectedEquipment = equipment
                                }
                        }
                    }
                    .padding(.horizontal)

                    // Add Equipment Button
                    if filteredEquipment.isEmpty {
                        EmptyStateCard(
                            icon: "wrench.and.screwdriver",
                            title: "No Equipment Found",
                            subtitle: searchText.isEmpty
                                ? "Add your first piece of equipment"
                                : "Try adjusting your search"
                        )
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $showingAddEquipment) {
                AddEquipmentView(equipmentManager: equipmentManager)
            }
            .sheet(item: $selectedEquipment) { equipment in
                EquipmentDetailView(equipment: equipment, equipmentManager: equipmentManager)
            }
        }
    }
}

struct EquipmentCard: View {
    let equipment: Equipment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: equipment.category.icon)
                    .font(.title2)
                    .foregroundColor(equipment.category.color)
                    .frame(width: 40, height: 40)
                    .background(equipment.category.color.opacity(0.1))
                    .cornerRadius(8)

                Spacer()

                Text(formatCurrency(equipment.hourlyRate) + "/hr")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(equipment.name)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .lineLimit(1)

                Text(equipment.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !equipment.manufacturer.isEmpty || !equipment.model.isEmpty {
                    Text("\(equipment.manufacturer) \(equipment.model)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 16) {
                HourlyBreakdownItem(
                    label: "Depr",
                    value: (equipment.purchasePrice - equipment.salvageValue) / equipment.expectedLifeHours
                )
                HourlyBreakdownItem(
                    label: "Fuel",
                    value: equipment.fuelBurnGPH * equipment.fuelPricePerGallon
                )
                HourlyBreakdownItem(
                    label: "Maint",
                    value: ((equipment.purchasePrice - equipment.salvageValue) / equipment.expectedLifeHours) * (equipment.maintenanceFactor / 100)
                )
            }
            .font(.caption2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct HourlyBreakdownItem: View {
    let label: String
    let value: Double

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .foregroundColor(.secondary)
            Text("$\(value, specifier: "%.2f")")
                .fontWeight(.medium)
        }
    }
}

struct AddEquipmentView: View {
    @ObservedObject var equipmentManager: EquipmentManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var selectedCategory: EquipmentCategory = .bucketTruck
    @State private var manufacturer = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())

    @State private var purchasePrice = ""
    @State private var salvagePercentage = ""
    @State private var expectedLifeHours = ""
    @State private var annualHours = ""
    @State private var fuelBurnGPH = ""
    @State private var fuelPrice = "4.25"
    @State private var maintenanceFactor = ""
    @State private var insuranceRate = ""

    @State private var useDefaults = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Equipment Information") {
                    TextField("Equipment Name", text: $name)

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(EquipmentCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .onChange(of: selectedCategory) { _ in
                        if useDefaults {
                            populateDefaults()
                        }
                    }

                    TextField("Manufacturer", text: $manufacturer)
                    TextField("Model", text: $model)
                    Stepper("Year: \(year)", value: $year, in: 2000...2030)
                }

                Section("Cost Calculation") {
                    Toggle("Use category defaults", isOn: $useDefaults)
                        .onChange(of: useDefaults) { newValue in
                            if newValue {
                                populateDefaults()
                            }
                        }

                    HStack {
                        Text("Purchase Price")
                        Spacer()
                        TextField("$", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    HStack {
                        Text("Salvage %")
                        Spacer()
                        TextField("%", text: $salvagePercentage)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Expected Life (hours)")
                        Spacer()
                        TextField("hours", text: $expectedLifeHours)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Annual Hours")
                        Spacer()
                        TextField("hours", text: $annualHours)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section("Operating Costs") {
                    HStack {
                        Text("Fuel Burn (gal/hr)")
                        Spacer()
                        TextField("gph", text: $fuelBurnGPH)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Fuel Price ($/gal)")
                        Spacer()
                        TextField("$", text: $fuelPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Maintenance Factor %")
                        Spacer()
                        TextField("%", text: $maintenanceFactor)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Insurance Rate %")
                        Spacer()
                        TextField("%", text: $insuranceRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                if let hourlyRate = calculateHourlyRate() {
                    Section("Calculated Hourly Rate") {
                        HStack {
                            Text("Total Hourly Cost")
                                .font(.headline)
                            Spacer()
                            Text(formatCurrency(hourlyRate) + "/hr")
                                .font(.title3.bold())
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Add Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEquipment()
                    }
                    .disabled(name.isEmpty || !isValidInput())
                }
            }
            .onAppear {
                populateDefaults()
            }
        }
    }

    private func populateDefaults() {
        let defaults = selectedCategory.defaultValues
        purchasePrice = String(format: "%.0f", defaults.purchasePrice)
        salvagePercentage = String(format: "%.0f", defaults.salvagePercentage)
        expectedLifeHours = String(format: "%.0f", defaults.expectedLifeHours)
        annualHours = String(format: "%.0f", defaults.annualHours)
        fuelBurnGPH = String(format: "%.1f", defaults.fuelBurnGPH)
        maintenanceFactor = String(format: "%.0f", defaults.maintenanceFactor)
        insuranceRate = String(format: "%.1f", defaults.insuranceRate)
    }

    private func isValidInput() -> Bool {
        guard let _ = Double(purchasePrice),
              let _ = Double(salvagePercentage),
              let _ = Double(expectedLifeHours),
              let _ = Double(annualHours),
              let _ = Double(fuelBurnGPH),
              let _ = Double(fuelPrice),
              let _ = Double(maintenanceFactor),
              let _ = Double(insuranceRate) else {
            return false
        }
        return true
    }

    private func calculateHourlyRate() -> Double? {
        guard let purchase = Double(purchasePrice),
              let salvagePercent = Double(salvagePercentage),
              let lifeHours = Double(expectedLifeHours),
              let annual = Double(annualHours),
              let fuel = Double(fuelBurnGPH),
              let fuelPriceVal = Double(fuelPrice),
              let maintenance = Double(maintenanceFactor),
              let insurance = Double(insuranceRate) else {
            return nil
        }

        let salvageValue = purchase * (salvagePercent / 100)
        let depreciation = (purchase - salvageValue) / lifeHours
        let interest = ((purchase + salvageValue) / 2 * 0.06) / annual
        let insuranceCost = (purchase * (insurance / 100)) / annual
        let fuelCost = fuel * fuelPriceVal
        let maintenanceCost = depreciation * (maintenance / 100)
        let wearParts = depreciation * 0.20

        return depreciation + interest + insuranceCost + fuelCost + maintenanceCost + wearParts
    }

    private func saveEquipment() {
        guard let purchase = Double(purchasePrice),
              let salvagePercent = Double(salvagePercentage),
              let lifeHours = Double(expectedLifeHours),
              let annual = Double(annualHours),
              let fuel = Double(fuelBurnGPH),
              let fuelPriceVal = Double(fuelPrice),
              let maintenance = Double(maintenanceFactor),
              let insurance = Double(insuranceRate) else {
            return
        }

        let newEquipment = Equipment(
            name: name,
            category: selectedCategory,
            manufacturer: manufacturer,
            model: model,
            year: year,
            purchasePrice: purchase,
            salvageValue: purchase * (salvagePercent / 100),
            expectedLifeHours: lifeHours,
            annualHours: annual,
            fuelBurnGPH: fuel,
            fuelPricePerGallon: fuelPriceVal,
            maintenanceFactor: maintenance,
            insuranceRate: insurance
        )

        equipmentManager.addEquipment(newEquipment)
        dismiss()
    }
}

struct EquipmentDetailView: View {
    let equipment: Equipment
    @ObservedObject var equipmentManager: EquipmentManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: equipment.category.icon)
                            .font(.system(size: 60))
                            .foregroundColor(equipment.category.color)

                        Text(equipment.name)
                            .font(.title2.bold())

                        Text(equipment.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()

                    // Hourly Cost
                    VStack(spacing: 8) {
                        Text("Total Hourly Cost")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(equipment.hourlyRate) + "/hr")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Cost Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cost Breakdown")
                            .font(.headline)

                        CostBreakdownRow(
                            label: "Depreciation",
                            value: (equipment.purchasePrice - equipment.salvageValue) / equipment.expectedLifeHours
                        )
                        CostBreakdownRow(
                            label: "Interest",
                            value: ((equipment.purchasePrice + equipment.salvageValue) / 2 * 0.06) / equipment.annualHours
                        )
                        CostBreakdownRow(
                            label: "Insurance",
                            value: (equipment.purchasePrice * (equipment.insuranceRate / 100)) / equipment.annualHours
                        )
                        CostBreakdownRow(
                            label: "Fuel",
                            value: equipment.fuelBurnGPH * equipment.fuelPricePerGallon
                        )
                        CostBreakdownRow(
                            label: "Maintenance",
                            value: ((equipment.purchasePrice - equipment.salvageValue) / equipment.expectedLifeHours) * (equipment.maintenanceFactor / 100)
                        )
                        CostBreakdownRow(
                            label: "Wear Parts",
                            value: ((equipment.purchasePrice - equipment.salvageValue) / equipment.expectedLifeHours) * 0.20
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Equipment Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Equipment Details")
                            .font(.headline)

                        DetailRow(label: "Manufacturer", value: equipment.manufacturer)
                        DetailRow(label: "Model", value: equipment.model)
                        DetailRow(label: "Year", value: String(equipment.year))
                        DetailRow(label: "Purchase Price", value: formatCurrency(equipment.purchasePrice))
                        DetailRow(label: "Expected Life", value: "\(Int(equipment.expectedLifeHours)) hours")
                        DetailRow(label: "Annual Hours", value: "\(Int(equipment.annualHours)) hours")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Equipment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CostBreakdownRow: View {
    let label: String
    let value: Double

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text("$\(value, specifier: "%.2f")/hr")
                .fontWeight(.medium)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// Helper function
func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
}