import SwiftUI
import CoreData

// MARK: - Ops Pricing Calculator View
// Comprehensive pricing calculator using TreeScore and Ops methods

struct OpsPricingCalculatorView: View {
    @ObservedObject var workOrder: CDWorkOrder
    let trees: [TreeInventoryItem]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // Pricing Parameters
    @State private var serviceType: ServiceType = .removal
    @State private var crewSize: Int = 2
    @State private var equipmentType: EquipmentType = .largeChipper
    @State private var includesCleanup = true
    @State private var includesHauling = false
    @State private var urgencyFactor: UrgencyFactor = .normal
    @State private var bulkDiscount: Double = 0.0

    // Calculation Results
    @State private var propertyPricing: PropertyPricingResult?
    @State private var showingDetailedBreakdown = false

    var body: some View {
        NavigationStack {
            Form {
                // Property Summary Section
                Section("Property Overview") {
                    LabeledContent("Customer", value: workOrder.customer?.name ?? "Unknown")
                    LabeledContent("Work Order", value: workOrder.workOrderNumber ?? "")
                    LabeledContent("Total Trees", value: "\(trees.count)")
                    LabeledContent("Total TreeScore", value: String(format: "%.1f", totalTreeScore))
                }

                // Service Configuration
                Section("Service Configuration") {
                    Picker("Service Type", selection: $serviceType) {
                        ForEach(ServiceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    Picker("Equipment", selection: $equipmentType) {
                        ForEach(EquipmentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    Stepper("Crew Size: \(crewSize)", value: $crewSize, in: 1...6)

                    Toggle("Includes Cleanup", isOn: $includesCleanup)
                    Toggle("Includes Hauling", isOn: $includesHauling)
                }

                // Urgency & Discounts
                Section("Pricing Adjustments") {
                    Picker("Urgency", selection: $urgencyFactor) {
                        ForEach(UrgencyFactor.allCases, id: \.self) { factor in
                            HStack {
                                Text(factor.rawValue)
                                Spacer()
                                Text("+\(Int((factor.multiplier - 1) * 100))%")
                                    .foregroundColor(.secondary)
                            }
                            .tag(factor)
                        }
                    }

                    HStack {
                        Text("Bulk Discount")
                        Spacer()
                        Text("\(Int(bulkDiscount * 100))%")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $bulkDiscount, in: 0...0.25, step: 0.05)
                }

                // Pricing Results
                if let pricing = propertyPricing {
                    Section("Pricing Summary") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Subtotal")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrency(pricing.subtotal))
                            }

                            if pricing.discount > 0 {
                                HStack {
                                    Text("Discount (\(Int(bulkDiscount * 100))%)")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("-\(formatCurrency(pricing.discount))")
                                        .foregroundColor(.green)
                                }
                            }

                            Divider()

                            HStack {
                                Text("Total Price")
                                    .font(.headline)
                                Spacer()
                                Text(formatCurrency(pricing.finalPrice))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }

                            // Time Estimate
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Est. Hours")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f hrs", pricing.totalHours))
                                        .font(.subheadline)
                                }

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text("Days Required")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(pricing.crewDaysRequired) days")
                                        .font(.subheadline)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }

                    // Detailed Breakdown Button
                    Section {
                        Button(action: { showingDetailedBreakdown = true }) {
                            Label("View Detailed Breakdown", systemImage: "list.bullet.rectangle")
                        }
                    }

                    // Profit Analysis
                    Section("Profit Analysis") {
                        if let firstTree = trees.first?.opsPricing {
                            HStack {
                                Text("Labor Cost")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrency(firstTree.laborCost * Double(trees.count)))
                            }

                            HStack {
                                Text("Equipment Cost")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrency(firstTree.equipmentCost * Double(trees.count)))
                            }

                            HStack {
                                Text("Profit Margin")
                                    .font(.headline)
                                Spacer()
                                Text("\(Int(firstTree.profitMargin * 100))%")
                                    .font(.headline)
                                    .foregroundColor(profitMarginColor(firstTree.profitMargin))
                            }
                        }
                    }
                }

                // Action Buttons
                Section {
                    Button(action: generateProposal) {
                        Label("Generate Proposal", systemImage: "doc.text.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(propertyPricing == nil)

                    Button(action: saveToWorkOrder) {
                        Label("Save to Work Order", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(propertyPricing == nil)
                }
            }
            .navigationTitle("Ops Pricing Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Calculate") { calculatePricing() }
                        .bold()
                }
            }
            .sheet(isPresented: $showingDetailedBreakdown) {
                if let pricing = propertyPricing {
                    DetailedPricingBreakdownView(pricing: pricing)
                }
            }
        }
        .onAppear {
            calculatePricing()
        }
    }

    var totalTreeScore: Double {
        trees.reduce(0) { $0 + $1.treeScore.finalTreeScore }
    }

    func calculatePricing() {
        // Calculate pricing for each tree
        for tree in trees {
            tree.calculateOpsPrice(
                serviceType: serviceType,
                crewSize: crewSize,
                equipmentType: equipmentType,
                includesCleanup: includesCleanup,
                includesHauling: includesHauling,
                urgencyFactor: urgencyFactor
            )
        }

        // Calculate property pricing
        propertyPricing = TreeScoreCalculator.calculatePropertyPrice(
            trees: trees,
            serviceType: serviceType,
            defaultCrewSize: crewSize,
            defaultEquipment: equipmentType,
            includesCleanup: includesCleanup,
            includesHauling: includesHauling,
            bulkDiscount: bulkDiscount
        )
    }

    func generateProposal() {
        guard let pricing = propertyPricing else { return }

        // Create a new proposal based on the pricing
        let proposal = CDProposal(context: viewContext)
        proposal.id = UUID()
        proposal.proposalNumber = "P-\(Date().timeIntervalSince1970)"
        proposal.customer = workOrder.customer
        proposal.createdAt = Date()
        proposal.updatedAt = Date()
        proposal.status = "Draft"
        proposal.subtotal = pricing.subtotal
        proposal.discount = pricing.discount
        proposal.total = pricing.finalPrice
        proposal.includesCleanup = includesCleanup
        proposal.includesHauling = includesHauling
        proposal.notes = "Generated from TreeScore analysis of \(trees.count) trees"

        // Create line items for each tree
        for detail in pricing.treeDetails {
            let lineItem = CDLineItem(context: viewContext)
            lineItem.id = UUID()
            lineItem.serviceType = serviceType.rawValue
            lineItem.itemDescription = "\(detail.species) - TreeScore: \(Int(detail.treeScore))"
            lineItem.quantity = 1
            lineItem.unitPrice = detail.price
            lineItem.totalPrice = detail.price
            lineItem.proposal = proposal
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error creating proposal: \(error)")
        }
    }

    func saveToWorkOrder() {
        guard let pricing = propertyPricing else { return }

        // Update work order with pricing information
        workOrder.estimatedDuration = pricing.totalHours

        // Add pricing info to safety notes (since notes field doesn't exist)
        let pricingInfo = """
        TreeScore Analysis:
        - Total Trees: \(trees.count)
        - Total TreeScore: \(Int(totalTreeScore))
        - Estimated Price: \(formatCurrency(pricing.finalPrice))
        - Estimated Hours: \(String(format: "%.1f", pricing.totalHours))
        - Crew Days Required: \(pricing.crewDaysRequired)
        - Recommended Crew Size: \(pricing.recommendedCrewSize)
        """

        if let existingNotes = workOrder.safetyNotes {
            workOrder.safetyNotes = existingNotes + "\n\n" + pricingInfo
        } else {
            workOrder.safetyNotes = pricingInfo
        }

        workOrder.updatedAt = Date()

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error updating work order: \(error)")
        }
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    func profitMarginColor(_ margin: Double) -> Color {
        switch margin {
        case ..<0.20:
            return .red
        case 0.20..<0.35:
            return .orange
        case 0.35..<0.50:
            return .green
        default:
            return .blue
        }
    }
}

// MARK: - Detailed Pricing Breakdown View
struct DetailedPricingBreakdownView: View {
    let pricing: PropertyPricingResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Property Summary") {
                    LabeledContent("Total Trees", value: "\(pricing.totalTrees)")
                    LabeledContent("Total TreeScore", value: String(format: "%.1f", pricing.totalTreeScore))
                    LabeledContent("Total Hours", value: String(format: "%.1f hrs", pricing.totalHours))
                    LabeledContent("Days Required", value: "\(pricing.crewDaysRequired)")
                }

                Section("Individual Tree Pricing") {
                    ForEach(pricing.treeDetails, id: \.treeId) { detail in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(detail.species)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(formatCurrency(detail.price))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            HStack {
                                Label("TreeScore: \(Int(detail.treeScore))", systemImage: "tree")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(String(format: "%.1f", detail.estimatedHours)) hrs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Price Breakdown") {
                    LabeledContent("Subtotal", value: formatCurrency(pricing.subtotal))
                    if pricing.discount > 0 {
                        LabeledContent("Discount", value: "-\(formatCurrency(pricing.discount))")
                            .foregroundColor(.green)
                    }
                    LabeledContent("Final Price", value: formatCurrency(pricing.finalPrice))
                        .font(.headline)
                }
            }
            .navigationTitle("Detailed Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Property Analysis View
struct PropertyAnalysisView: View {
    @ObservedObject var workOrder: CDWorkOrder
    let trees: [TreeInventoryItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // TreeScore Distribution
                    TreeScoreDistributionCard(trees: trees)

                    // Species Breakdown
                    SpeciesBreakdownCard(trees: trees)

                    // Complexity Analysis
                    ComplexityAnalysisCard(trees: trees)

                    // Risk Assessment
                    RiskAssessmentCard(trees: trees)

                    // Time & Resource Planning
                    ResourcePlanningCard(trees: trees)
                }
                .padding()
            }
            .navigationTitle("Property Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// Analysis Card Components
struct TreeScoreDistributionCard: View {
    let trees: [TreeInventoryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TreeScore Distribution")
                .font(.headline)

            ForEach(TreeComplexity.allCases, id: \.self) { complexity in
                let count = trees.filter { $0.complexity == complexity }.count
                if count > 0 {
                    HStack {
                        Image(systemName: complexity.iconName)
                            .foregroundColor(Color(hex: complexity.color))
                        Text(complexity.rawValue)
                        Spacer()
                        Text("\(count) trees")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SpeciesBreakdownCard: View {
    let trees: [TreeInventoryItem]

    var speciesCount: [(String, Int)] {
        let grouped = Dictionary(grouping: trees) { $0.species ?? "Unknown" }
        return grouped.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Species Breakdown")
                .font(.headline)

            ForEach(speciesCount, id: \.0) { species, count in
                HStack {
                    Text(species)
                    Spacer()
                    Text("\(count)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ComplexityAnalysisCard: View {
    let trees: [TreeInventoryItem]

    var averageTreeScore: Double {
        guard !trees.isEmpty else { return 0 }
        return trees.reduce(0) { $0 + $1.treeScore.finalTreeScore } / Double(trees.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Complexity Analysis")
                .font(.headline)

            HStack {
                Text("Average TreeScore")
                Spacer()
                Text(String(format: "%.1f", averageTreeScore))
                    .fontWeight(.semibold)
            }

            HStack {
                Text("Highest TreeScore")
                Spacer()
                Text(String(format: "%.1f", trees.map { $0.treeScore.finalTreeScore }.max() ?? 0))
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }

            HStack {
                Text("Lowest TreeScore")
                Spacer()
                Text(String(format: "%.1f", trees.map { $0.treeScore.finalTreeScore }.min() ?? 0))
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RiskAssessmentCard: View {
    let trees: [TreeInventoryItem]

    var riskBreakdown: [(RiskLevel, Int)] {
        let grouped = Dictionary(grouping: trees) { $0.riskLevel }
        return grouped.map { ($0.key, $0.value.count) }.sorted { $0.0.rawValue < $1.0.rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Assessment")
                .font(.headline)

            ForEach(riskBreakdown, id: \.0.rawValue) { risk, count in
                HStack {
                    Circle()
                        .fill(Color(hex: risk.color))
                        .frame(width: 10, height: 10)
                    Text("\(risk.rawValue) Risk")
                    Spacer()
                    Text("\(count) trees")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ResourcePlanningCard: View {
    let trees: [TreeInventoryItem]

    var totalEstimatedHours: Double {
        // Assuming average PpH of 50
        trees.reduce(0) { $0 + $1.treeScore.finalTreeScore } / 50.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resource Planning")
                .font(.headline)

            HStack {
                Text("Estimated Total Hours")
                Spacer()
                Text(String(format: "%.1f hrs", totalEstimatedHours))
                    .fontWeight(.semibold)
            }

            HStack {
                Text("Recommended Crew Size")
                Spacer()
                Text(totalEstimatedHours > 40 ? "3-4 people" : "2 people")
                    .fontWeight(.semibold)
            }

            HStack {
                Text("Estimated Days")
                Spacer()
                Text("\(Int(ceil(totalEstimatedHours / 8.0))) days")
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}