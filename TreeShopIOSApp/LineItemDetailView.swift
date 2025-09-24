import SwiftUI

struct LineItemDetailView: View {
    let item: LineItem
    @State private var selectedPackage: ServicePackage? = nil
    @State private var showingRateCalculator = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderSection(item: item)

                DescriptionSection(description: item.description)

                MeasurementSection(
                    unitOfMeasurement: item.unitOfMeasurement,
                    rateCalculation: item.rateCalculation,
                    showingRateCalculator: $showingRateCalculator
                )

                if let packages = item.packages {
                    PackagesSection(packages: packages, selectedPackage: $selectedPackage)
                }

                InclusionsSection(inclusions: item.inclusions)

                if !item.exclusions.isEmpty {
                    ExclusionsSection(exclusions: item.exclusions)
                }

                QuickActionsSection(item: item)
            }
            .padding()
        }
        .navigationTitle(item.category.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingRateCalculator) {
            RateCalculatorView(item: item)
        }
    }
}

struct HeaderSection: View {
    let item: LineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: item.category.icon)
                    .font(.largeTitle)
                    .foregroundColor(item.category.color)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Service Code")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(item.category.rawValue.prefix(3).uppercased()))
                        .font(.headline)
                        .foregroundColor(item.category.color)
                }
            }

            Text(item.name)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(item.category.color.opacity(0.1))
        )
    }
}

struct DescriptionSection: View {
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Description", systemImage: "text.alignleft")
                .font(.headline)
                .foregroundColor(.primary)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct MeasurementSection: View {
    let unitOfMeasurement: String
    let rateCalculation: String
    @Binding var showingRateCalculator: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pricing & Measurement", systemImage: "dollarsign.circle")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Unit:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(unitOfMeasurement)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Formula:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                Text(rateCalculation)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            Button(action: {
                showingRateCalculator = true
            }) {
                Label("Calculate Rate", systemImage: "function")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct PackagesSection: View {
    let packages: [ServicePackage]
    @Binding var selectedPackage: ServicePackage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Service Packages", systemImage: "shippingbox")
                .font(.headline)

            ForEach(packages) { package in
                PackageCard(
                    package: package,
                    isSelected: selectedPackage?.id == package.id,
                    action: {
                        withAnimation {
                            selectedPackage = selectedPackage?.id == package.id ? nil : package
                        }
                    }
                )
            }
        }
    }
}

struct PackageCard: View {
    let package: ServicePackage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(package.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                }

                Text(package.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isSelected {
                    Text(package.details)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InclusionsSection: View {
    let inclusions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What's Included", systemImage: "checkmark.circle")
                .font(.headline)
                .foregroundColor(.green)

            ForEach(inclusions, id: \.self) { inclusion in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.caption)
                        .padding(.top, 2)
                    Text(inclusion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ExclusionsSection: View {
    let exclusions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Not Included", systemImage: "xmark.circle")
                .font(.headline)
                .foregroundColor(.orange)

            ForEach(exclusions, id: \.self) { exclusion in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "xmark")
                        .foregroundColor(.orange)
                        .font(.caption)
                        .padding(.top, 2)
                    Text(exclusion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct QuickActionsSection: View {
    let item: LineItem
    @State private var showingQuote = false
    @State private var showingSchedule = false

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingQuote = true
            }) {
                Label("Get Quote", systemImage: "doc.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(item.category.color)

            HStack(spacing: 12) {
                Button(action: {
                    showingSchedule = true
                }) {
                    Label("Schedule", systemImage: "calendar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    // Share action
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top)
        .sheet(isPresented: $showingQuote) {
            QuoteRequestView(item: item)
        }
        .sheet(isPresented: $showingSchedule) {
            ScheduleView(item: item)
        }
    }
}

struct RateCalculatorView: View {
    let item: LineItem
    @Environment(\.dismiss) var dismiss
    @State private var treeScore: String = ""
    @State private var afissMultiplier: String = "1.0"
    @State private var crewPpH: String = "100"
    @State private var loadoutRate: String = "250"

    var calculatedHours: Double? {
        guard let score = Double(treeScore),
              let multiplier = Double(afissMultiplier),
              let pph = Double(crewPpH),
              pph > 0 else { return nil }

        return (score * multiplier) / pph
    }

    var totalCost: Double? {
        guard let hours = calculatedHours,
              let rate = Double(loadoutRate) else { return nil }
        return hours * rate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Input Parameters") {
                    HStack {
                        Text("TreeScore Points")
                        Spacer()
                        TextField("0", text: $treeScore)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("AFISS Multiplier")
                        Spacer()
                        TextField("1.0", text: $afissMultiplier)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Crew PpH")
                        Spacer()
                        TextField("100", text: $crewPpH)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Loadout Rate")
                        Spacer()
                        TextField("250", text: $loadoutRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Calculation") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Formula")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(item.rateCalculation)
                            .font(.caption2)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                if calculatedHours != nil && totalCost != nil {
                    Section("Results") {
                        HStack {
                            Text("Estimated Hours")
                            Spacer()
                            Text(String(format: "%.2f hrs", calculatedHours!))
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Total Cost")
                            Spacer()
                            Text(String(format: "$%.2f", totalCost!))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Rate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct QuoteRequestView: View {
    let item: LineItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Quote Request Form")
                    .font(.title)
                Text("Coming Soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Request Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ScheduleView: View {
    let item: LineItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Schedule Service")
                    .font(.title)
                Text("Coming Soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LineItemDetailView(item: LineItemsData().items.first!)
    }
}