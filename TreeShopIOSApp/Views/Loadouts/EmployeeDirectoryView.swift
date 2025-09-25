import SwiftUI

struct EmployeeDirectoryView: View {
    @EnvironmentObject var employeeManager: EmployeeManager
    @State private var showingAddEmployee = false
    @State private var selectedEmployee: Employee?
    @State private var searchText = ""
    @State private var selectedPosition: EmployeePosition?

    var filteredEmployees: [Employee] {
        let positionFiltered = selectedPosition != nil
            ? employeeManager.employees.filter { $0.position == selectedPosition }
            : employeeManager.employees

        if searchText.isEmpty {
            return positionFiltered
        } else {
            return positionFiltered.filter { employee in
                employee.fullName.localizedCaseInsensitiveContains(searchText) ||
                employee.position.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Add button
            HStack {
                Text("Employees")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: { showingAddEmployee = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            .padding()

            ScrollView {
                VStack(spacing: 20) {
                    // Position Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryFilterChip(
                                title: "All",
                                isSelected: selectedPosition == nil,
                                color: .gray
                            ) {
                                withAnimation { selectedPosition = nil }
                            }

                            ForEach(EmployeePosition.allCases) { position in
                                CategoryFilterChip(
                                    title: position.rawValue,
                                    isSelected: selectedPosition == position,
                                    color: position.color
                                ) {
                                    withAnimation {
                                        selectedPosition = selectedPosition == position ? nil : position
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Employee List with Lazy Loading
                    LazyVStack(spacing: 16) {
                        ForEach(filteredEmployees) { employee in
                            EmployeeCard(employee: employee, employeeManager: employeeManager)
                                .onTapGesture {
                                    selectedEmployee = employee
                                }
                                .id(employee.id)
                        }
                    }
                    .padding(.horizontal)

                    if filteredEmployees.isEmpty {
                        EmptyStateCard(
                            icon: "person.2",
                            title: searchText.isEmpty
                                ? "No Employees Yet"
                                : "No Results",
                            subtitle: searchText.isEmpty
                                ? "Add your first employee"
                                : "Try adjusting your search"
                        )
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $showingAddEmployee) {
                AddEmployeeView(employeeManager: employeeManager)
            }
            .sheet(item: $selectedEmployee) { employee in
                EmployeeDetailView(employee: employee, employeeManager: employeeManager)
            }
        }
    }
}

struct EmployeeCard: View {
    let employee: Employee
    let employeeManager: EmployeeManager

    var burdenBreakdown: BurdenCostBreakdown {
        employeeManager.calculateTotalBurdenCost(for: employee)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: employee.position.icon)
                    .font(.largeTitle)
                    .foregroundColor(employee.position.color)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(employee.fullName)
                        .font(.headline)
                    Text(employee.position.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(employee.trueHourlyCost, specifier: "%.2f")/hr")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("\(employee.burdenMultiplier, specifier: "%.2f")x burden")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            // Cost Breakdown
            VStack(spacing: 8) {
                EmployeeCostBreakdownRow(label: "Base Wage", amount: employee.baseHourlyRate, isBase: true)
                EmployeeCostBreakdownRow(label: "Tax & Benefits", amount: employee.trueHourlyCost - employee.baseHourlyRate, isAddition: true)
                Divider()
                EmployeeCostBreakdownRow(label: "True Cost", amount: employee.trueHourlyCost, isTotal: true)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct EmployeeCostBreakdownRow: View {
    let label: String
    let amount: Double
    var isBase: Bool = false
    var isAddition: Bool = false
    var isTotal: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .subheadline.bold() : .subheadline)
                .foregroundColor(isTotal ? .primary : .secondary)
            Spacer()
            Text(isAddition ? "+$\(amount, specifier: "%.2f")/hr" : "$\(amount, specifier: "%.2f")/hr")
                .font(isTotal ? .subheadline.bold() : .subheadline)
                .foregroundColor(isTotal ? .green : (isAddition ? .orange : .primary))
        }
    }
}

struct PositionFilterChip: View {
    let position: EmployeePosition?
    let isSelected: Bool
    let action: () -> Void

    var title: String {
        position?.rawValue ?? "All"
    }

    var color: Color {
        position?.color ?? .gray
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add/Edit Views

struct AddEmployeeView: View {
    let employeeManager: EmployeeManager
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var position: EmployeePosition = .groundCrewEntry
    @State private var baseHourlyRate = "18.00"

    var body: some View {
        NavigationStack {
            Form {
                Section("Employee Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)

                    Picker("Position", selection: $position) {
                        ForEach(EmployeePosition.allCases) { position in
                            Label(position.rawValue, systemImage: position.icon)
                                .tag(position)
                        }
                    }

                    HStack {
                        Text("Base Hourly Rate")
                        Spacer()
                        TextField("Rate", text: $baseHourlyRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("/hr")
                    }
                }

                Section("Cost Preview") {
                    let rate = Double(baseHourlyRate) ?? 18.0
                    let burden = position.defaultBurdenMultiplier
                    let trueCost = rate * burden

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Base Rate")
                            Spacer()
                            Text("$\(rate, specifier: "%.2f")/hr")
                        }
                        HStack {
                            Text("Burden Multiplier")
                            Spacer()
                            Text("\(burden, specifier: "%.2f")x")
                        }
                        Divider()
                        HStack {
                            Text("True Hourly Cost")
                                .bold()
                            Spacer()
                            Text("$\(trueCost, specifier: "%.2f")/hr")
                                .bold()
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Add Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newEmployee = Employee(
                            firstName: firstName,
                            lastName: lastName,
                            position: position,
                            baseHourlyRate: Double(baseHourlyRate) ?? 18.0
                        )
                        employeeManager.addEmployee(newEmployee)
                        dismiss()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }
}

struct EmployeeDetailView: View {
    let employee: Employee
    let employeeManager: EmployeeManager
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String
    @State private var lastName: String
    @State private var position: EmployeePosition
    @State private var baseHourlyRate: String

    init(employee: Employee, employeeManager: EmployeeManager) {
        self.employee = employee
        self.employeeManager = employeeManager
        _firstName = State(initialValue: employee.firstName)
        _lastName = State(initialValue: employee.lastName)
        _position = State(initialValue: employee.position)
        _baseHourlyRate = State(initialValue: String(format: "%.2f", employee.baseHourlyRate))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Employee Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)

                    Picker("Position", selection: $position) {
                        ForEach(EmployeePosition.allCases) { position in
                            Label(position.rawValue, systemImage: position.icon)
                                .tag(position)
                        }
                    }

                    HStack {
                        Text("Base Hourly Rate")
                        Spacer()
                        TextField("Rate", text: $baseHourlyRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("/hr")
                    }
                }

                Section("Cost Analysis") {
                    let rate = Double(baseHourlyRate) ?? 18.0
                    let burden = position.defaultBurdenMultiplier
                    let trueCost = rate * burden

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Base Rate")
                            Spacer()
                            Text("$\(rate, specifier: "%.2f")/hr")
                        }
                        HStack {
                            Text("Burden Multiplier")
                            Spacer()
                            Text("\(burden, specifier: "%.2f")x")
                        }
                        Divider()
                        HStack {
                            Text("True Hourly Cost")
                                .bold()
                            Spacer()
                            Text("$\(trueCost, specifier: "%.2f")/hr")
                                .bold()
                                .foregroundColor(.green)
                        }
                    }
                }

                Section {
                    Button(action: {
                        employeeManager.deleteEmployee(employee)
                        dismiss()
                    }) {
                        Text("Delete Employee")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Edit Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedEmployee = employee
                        updatedEmployee.firstName = firstName
                        updatedEmployee.lastName = lastName
                        updatedEmployee.position = position
                        updatedEmployee.baseHourlyRate = Double(baseHourlyRate) ?? 18.0
                        employeeManager.updateEmployee(updatedEmployee)
                        dismiss()
                    }
                }
            }
        }
    }
}
