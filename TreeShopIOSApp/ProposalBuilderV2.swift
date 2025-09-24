import SwiftUI
import Foundation

// MARK: - Line Item Models

enum LineItemType: String, CaseIterable {
    case treeRemoval = "Tree Removal"
    case treeTrimming = "Tree Trimming"
    case stumpGrinding = "Stump Grinding"
    case forestryMulching = "Forestry Mulching"
    case emergency = "Emergency Service"
    case landClearing = "Land Clearing"
    case craneRemoval = "Crane Removal"
    case healthAssessment = "Health Assessment"
    case woodRetention = "Wood Retention"
    case rightOfWay = "Right-of-Way"

    var icon: String {
        switch self {
        case .treeRemoval: return "leaf.fill"
        case .treeTrimming: return "scissors"
        case .stumpGrinding: return "circle.grid.3x3.fill"
        case .forestryMulching: return "rectangle.compress.vertical"
        case .emergency: return "exclamationmark.triangle.fill"
        case .landClearing: return "map.fill"
        case .craneRemoval: return "arrow.up.to.line"
        case .healthAssessment: return "heart.text.square.fill"
        case .woodRetention: return "shippingbox.fill"
        case .rightOfWay: return "road.lanes"
        }
    }

    var baseRate: Double {
        switch self {
        case .treeRemoval: return 750
        case .treeTrimming: return 450
        case .stumpGrinding: return 250
        case .forestryMulching: return 2500
        case .emergency: return 1200
        case .landClearing: return 3000
        case .craneRemoval: return 2000
        case .healthAssessment: return 150
        case .woodRetention: return 200
        case .rightOfWay: return 1500
        }
    }

    var unitType: String {
        switch self {
        case .treeRemoval, .treeTrimming: return "per tree"
        case .stumpGrinding: return "per stump"
        case .forestryMulching: return "per acre"
        case .emergency: return "per hour"
        case .landClearing: return "per day"
        case .craneRemoval: return "per lift"
        case .healthAssessment: return "per assessment"
        case .woodRetention: return "per cord"
        case .rightOfWay: return "per 100ft"
        }
    }
}

struct ProposalLineItem: Identifiable {
    let id = UUID()
    var type: LineItemType
    var quantity: Double = 1
    var description: String = ""

    // Tree-specific measurements
    var height: Double? // feet
    var dbh: Double? // diameter in inches
    var canopySpread: Double? // feet
    var trimPercent: Double? // for trimming

    // Stump-specific
    var stumpDiameter: Double? // inches
    var grindDepth: Double? = 8 // inches

    // Land clearing
    var acres: Double?
    var maxDBH: Double? // max tree size to mulch

    // Complexity factors
    var accessDifficulty: Double = 1.0 // 1.0 = easy, 1.5 = medium, 2.0 = hard
    var nearStructure: Bool = false
    var powerLines: Bool = false
    var slope: Bool = false

    // Calculated fields
    var treeScore: Double {
        guard let height = height, let dbh = dbh else { return 0 }
        let canopy = canopySpread ?? 0
        return height + (dbh * 2) + canopy
    }

    var complexityMultiplier: Double {
        var multiplier = accessDifficulty
        if nearStructure { multiplier *= 1.3 }
        if powerLines { multiplier *= 1.4 }
        if slope { multiplier *= 1.2 }
        return multiplier
    }

    var adjustedScore: Double {
        if type == .treeTrimming, let percent = trimPercent {
            return treeScore * (percent / 100) * complexityMultiplier
        }
        return treeScore * complexityMultiplier
    }

    var calculatedPrice: Double {
        switch type {
        case .treeRemoval:
            // Price based on tree score
            let basePrice = adjustedScore * 4 // $4 per point
            return max(basePrice, type.baseRate) * quantity

        case .treeTrimming:
            // Price based on percentage of tree
            let basePrice = adjustedScore * 3 // $3 per adjusted point
            return max(basePrice, type.baseRate) * quantity

        case .stumpGrinding:
            // Price based on diameter and depth
            let diameter = stumpDiameter ?? 12
            let depth = grindDepth ?? 8
            let basePrice = diameter * depth * 2.5 // $2.50 per inch²
            return max(basePrice, type.baseRate) * quantity

        case .forestryMulching:
            // Price per acre with DBH factor
            let acreage = acres ?? 1
            let dbhFactor = (maxDBH ?? 6) / 6 // 6" is standard
            return type.baseRate * acreage * dbhFactor * quantity

        case .landClearing:
            // Daily rate
            return type.baseRate * quantity

        case .emergency:
            // Hourly rate with 2x multiplier
            return type.baseRate * 2 * quantity

        default:
            // Simple quantity × base rate
            return type.baseRate * quantity
        }
    }

    var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: calculatedPrice)) ?? "$0"
    }

    var summary: String {
        switch type {
        case .treeRemoval:
            if let height = height, let dbh = dbh {
                return "\(Int(height))' tall, \(Int(dbh))\" diameter"
            }
            return "Tree removal"

        case .treeTrimming:
            if let percent = trimPercent {
                return "\(Int(percent))% trim"
            }
            return "Tree trimming"

        case .stumpGrinding:
            if let diameter = stumpDiameter {
                return "\(Int(diameter))\" stump, \(Int(grindDepth ?? 8))\" deep"
            }
            return "Stump grinding"

        case .forestryMulching:
            if let acres = acres {
                return "\(acres) acres, up to \(Int(maxDBH ?? 6))\" trees"
            }
            return "Forestry mulching"

        default:
            return "\(quantity) \(type.unitType)"
        }
    }
}

struct ProposalV2: Identifiable {
    let id = UUID()
    var customerName: String = ""
    var customerEmail: String = ""
    var customerPhone: String = ""
    var propertyAddress: String = ""
    var lineItems: [ProposalLineItem] = []
    var notes: String = ""
    var validDays: Int = 7
    var includesCleanup: Bool = true
    var includesHauling: Bool = true
    let createdDate = Date()

    var subtotal: Double {
        lineItems.reduce(0) { $0 + $1.calculatedPrice }
    }

    var discount: Double {
        // Bundle discounts
        if lineItems.count >= 5 { return 0.15 }
        if lineItems.count >= 3 { return 0.10 }
        if lineItems.count >= 2 { return 0.05 }
        return 0
    }

    var discountAmount: Double {
        subtotal * discount
    }

    var total: Double {
        subtotal - discountAmount
    }
}

// MARK: - Proposal Builder View

struct ProposalBuilderV2View: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var proposal = ProposalV2()
    @State private var showingAddLineItem = false
    @State private var editingLineItem: ProposalLineItem?
    @State private var showingProposal = false
    @State private var showingSaveConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                // Customer Information
                Section("Customer Information") {
                    TextField("Customer Name", text: $proposal.customerName)
                    TextField("Email", text: $proposal.customerEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $proposal.customerPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Property Address", text: $proposal.propertyAddress)
                        .textContentType(.fullStreetAddress)
                }

                // Line Items
                Section("Services") {
                    if proposal.lineItems.isEmpty {
                        Button(action: { showingAddLineItem = true }) {
                            Label("Add First Service", systemImage: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    } else {
                        ForEach($proposal.lineItems) { $item in
                            LineItemRow(item: item) {
                                editingLineItem = item
                            }
                        }
                        .onDelete { indexSet in
                            proposal.lineItems.remove(atOffsets: indexSet)
                        }

                        Button(action: { showingAddLineItem = true }) {
                            Label("Add Service", systemImage: "plus.circle")
                                .font(.footnote)
                        }
                    }
                }

                // Options
                Section("Options") {
                    Toggle("Include Cleanup", isOn: $proposal.includesCleanup)
                    Toggle("Include Hauling", isOn: $proposal.includesHauling)

                    HStack {
                        Text("Valid for")
                        Picker("Days", selection: $proposal.validDays) {
                            Text("3 days").tag(3)
                            Text("7 days").tag(7)
                            Text("14 days").tag(14)
                            Text("30 days").tag(30)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }

                // Notes
                Section("Additional Notes") {
                    TextEditor(text: $proposal.notes)
                        .frame(minHeight: 60)
                }

                // Pricing Summary
                if !proposal.lineItems.isEmpty {
                    Section("Pricing Summary") {
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(formatCurrency(proposal.subtotal))
                        }

                        if proposal.discount > 0 {
                            HStack {
                                Text("Bundle Discount (\(Int(proposal.discount * 100))%)")
                                    .foregroundColor(.green)
                                Spacer()
                                Text("-\(formatCurrency(proposal.discountAmount))")
                                    .foregroundColor(.green)
                            }
                        }

                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text(formatCurrency(proposal.total))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("TSO Proposal Builder")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate") {
                        showingProposal = true
                    }
                    .disabled(proposal.lineItems.isEmpty || proposal.customerName.isEmpty)
                    .bold()
                }
            }
            .sheet(isPresented: $showingAddLineItem) {
                AddLineItemView { newItem in
                    proposal.lineItems.append(newItem)
                }
            }
            .sheet(item: $editingLineItem) { item in
                EditLineItemView(item: item) { updatedItem in
                    if let index = proposal.lineItems.firstIndex(where: { $0.id == item.id }) {
                        proposal.lineItems[index] = updatedItem
                    }
                }
            }
            .sheet(isPresented: $showingProposal) {
                FinalProposalView(proposal: proposal, onSave: saveProposal)
            }
            .alert("Proposal Saved", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your proposal has been saved successfully.")
            }
        }
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    func saveProposal() {
        let coreDataManager = CoreDataManager()
        _ = coreDataManager.saveProposal(from: proposal)
        showingSaveConfirmation = true
    }
}

// MARK: - Line Item Row

struct LineItemRow: View {
    let item: ProposalLineItem
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.type.icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.type.rawValue)
                        .font(.headline)
                    Text(item.summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(item.displayPrice)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            if !item.description.isEmpty {
                Text(item.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }

            // Complexity indicators
            if item.complexityMultiplier > 1.0 {
                HStack(spacing: 8) {
                    if item.nearStructure {
                        Tag(text: "Near Structure", color: .orange)
                    }
                    if item.powerLines {
                        Tag(text: "Power Lines", color: .red)
                    }
                    if item.slope {
                        Tag(text: "Slope", color: .brown)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}

struct Tag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

// MARK: - Add Line Item View

struct AddLineItemView: View {
    @Environment(\.dismiss) var dismiss
    @State private var lineItem = ProposalLineItem(type: .treeRemoval)
    let onAdd: (ProposalLineItem) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Service Type") {
                    Picker("Type", selection: $lineItem.type) {
                        ForEach(LineItemType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                        }
                    }

                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("1", value: $lineItem.quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text(lineItem.type.unitType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Dynamic fields based on type
                switch lineItem.type {
                case .treeRemoval, .treeTrimming:
                    TreeMeasurementsSection(
                        height: $lineItem.height,
                        dbh: $lineItem.dbh,
                        canopySpread: $lineItem.canopySpread,
                        trimPercent: lineItem.type == .treeTrimming ? $lineItem.trimPercent : .constant(nil)
                    )

                case .stumpGrinding:
                    StumpMeasurementsSection(
                        diameter: $lineItem.stumpDiameter,
                        depth: Binding(
                            get: { lineItem.grindDepth ?? 8 },
                            set: { lineItem.grindDepth = $0 }
                        )
                    )

                case .forestryMulching:
                    MulchingSection(
                        acres: $lineItem.acres,
                        maxDBH: $lineItem.maxDBH
                    )

                default:
                    EmptyView()
                }

                // Complexity factors
                ComplexitySection(
                    accessDifficulty: $lineItem.accessDifficulty,
                    nearStructure: $lineItem.nearStructure,
                    powerLines: $lineItem.powerLines,
                    slope: $lineItem.slope
                )

                // Additional notes
                Section("Additional Details") {
                    TextField("Notes (optional)", text: $lineItem.description)
                }

                // Price preview
                Section("Estimated Price") {
                    HStack {
                        Text("Base Price")
                        Spacer()
                        Text(formatCurrency(lineItem.type.baseRate))
                    }

                    if lineItem.treeScore > 0 {
                        HStack {
                            Text("TreeScore")
                            Spacer()
                            Text("\(Int(lineItem.treeScore)) points")
                        }
                    }

                    if lineItem.complexityMultiplier > 1.0 {
                        HStack {
                            Text("Complexity Factor")
                            Spacer()
                            Text(String(format: "%.1fx", lineItem.complexityMultiplier))
                                .foregroundColor(.orange)
                        }
                    }

                    HStack {
                        Text("Line Total")
                            .font(.headline)
                        Spacer()
                        Text(lineItem.displayPrice)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Add Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd(lineItem)
                        dismiss()
                    }
                    .bold()
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

// MARK: - Edit Line Item View

struct EditLineItemView: View {
    @Environment(\.dismiss) var dismiss
    @State private var lineItem: ProposalLineItem
    let onSave: (ProposalLineItem) -> Void

    init(item: ProposalLineItem, onSave: @escaping (ProposalLineItem) -> Void) {
        self._lineItem = State(initialValue: item)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            // Same form as AddLineItemView but with Save instead of Add
            Form {
                // ... (same content as AddLineItemView)
            }
            .navigationTitle("Edit Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(lineItem)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Measurement Sections

struct TreeMeasurementsSection: View {
    @Binding var height: Double?
    @Binding var dbh: Double?
    @Binding var canopySpread: Double?
    @Binding var trimPercent: Double?

    var body: some View {
        Section("Tree Measurements") {
            HStack {
                Label("Height", systemImage: "arrow.up")
                Spacer()
                TextField("0", value: $height, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("feet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("DBH", systemImage: "circle")
                Spacer()
                TextField("0", value: $dbh, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("inches")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("Canopy", systemImage: "cloud")
                Spacer()
                TextField("0", value: $canopySpread, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("feet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if trimPercent != nil {
                HStack {
                    Label("Trim %", systemImage: "scissors")
                    Spacer()
                    TextField("0", value: $trimPercent, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct StumpMeasurementsSection: View {
    @Binding var diameter: Double?
    @Binding var depth: Double

    var body: some View {
        Section("Stump Details") {
            HStack {
                Label("Diameter", systemImage: "circle")
                Spacer()
                TextField("0", value: $diameter, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("inches")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("Grind Depth", systemImage: "arrow.down")
                Spacer()
                Picker("Depth", selection: $depth) {
                    Text("6\"").tag(6.0)
                    Text("8\"").tag(8.0)
                    Text("12\"").tag(12.0)
                    Text("18\"").tag(18.0)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
}

struct MulchingSection: View {
    @Binding var acres: Double?
    @Binding var maxDBH: Double?

    var body: some View {
        Section("Mulching Details") {
            HStack {
                Label("Acres", systemImage: "map")
                Spacer()
                TextField("0", value: $acres, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("acres")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("Max Tree Size", systemImage: "tree")
                Spacer()
                Picker("Max DBH", selection: Binding(
                    get: { maxDBH ?? 6 },
                    set: { maxDBH = $0 }
                )) {
                    Text("4\"").tag(4.0)
                    Text("6\"").tag(6.0)
                    Text("8\"").tag(8.0)
                    Text("10\"").tag(10.0)
                    Text("12\"").tag(12.0)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
}

struct ComplexitySection: View {
    @Binding var accessDifficulty: Double
    @Binding var nearStructure: Bool
    @Binding var powerLines: Bool
    @Binding var slope: Bool

    var body: some View {
        Section("Site Complexity") {
            Picker("Access", selection: $accessDifficulty) {
                Text("Easy").tag(1.0)
                Text("Medium").tag(1.5)
                Text("Hard").tag(2.0)
            }
            .pickerStyle(SegmentedPickerStyle())

            Toggle("Near Structure", isOn: $nearStructure)
            Toggle("Power Lines", isOn: $powerLines)
            Toggle("Slope/Hill", isOn: $slope)
        }
    }
}

// MARK: - Final Proposal View

struct FinalProposalView: View {
    let proposal: ProposalV2
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false

    var proposalText: String {
        var text = """
        TREESHOP PROFESSIONAL SERVICES
        Proposal #\(Date().formatted(date: .numeric, time: .omitted))-001

        CUSTOMER: \(proposal.customerName)
        PROPERTY: \(proposal.propertyAddress)
        DATE: \(Date().formatted(date: .abbreviated, time: .omitted))
        VALID: \(proposal.validDays) days

        SERVICES:
        """

        for (index, item) in proposal.lineItems.enumerated() {
            text += "\n\(index + 1). \(item.type.rawValue)"
            text += "\n   \(item.summary)"
            if !item.description.isEmpty {
                text += "\n   Note: \(item.description)"
            }
            text += "\n   Price: \(item.displayPrice)"
        }

        text += "\n\nSUBTOTAL: \(formatCurrency(proposal.subtotal))"

        if proposal.discount > 0 {
            text += "\nDISCOUNT (\(Int(proposal.discount * 100))%): -\(formatCurrency(proposal.discountAmount))"
        }

        text += "\n\nTOTAL: \(formatCurrency(proposal.total))"

        text += """


        INCLUDES:
        ✓ Professional service by certified arborists
        ✓ Complete cleanup and debris removal
        ✓ Property protection guarantee
        ✓ Full insurance coverage

        PAYMENT TERMS:
        • 25% deposit to schedule
        • Balance due upon completion
        • All major cards accepted

        Licensed & Insured | ISA Certified
        100% Satisfaction Guaranteed
        """

        return text
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TREESHOP")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Professional Tree Services")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Proposal #\(Date().formatted(date: .numeric, time: .omitted))-001")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)

                    // Customer Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Customer Information")
                            .font(.headline)

                        HStack {
                            Text("Name:")
                                .foregroundColor(.secondary)
                            Text(proposal.customerName)
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Property:")
                                .foregroundColor(.secondary)
                            Text(proposal.propertyAddress)
                                .fontWeight(.medium)
                        }

                        if !proposal.customerEmail.isEmpty {
                            HStack {
                                Text("Email:")
                                    .foregroundColor(.secondary)
                                Text(proposal.customerEmail)
                                    .fontWeight(.medium)
                            }
                        }
                    }

                    Divider()

                    // Line Items
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Services")
                            .font(.headline)

                        ForEach(Array(proposal.lineItems.enumerated()), id: \.element.id) { index, item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(index + 1).")
                                        .fontWeight(.medium)
                                        .frame(width: 20)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.type.rawValue)
                                            .fontWeight(.semibold)
                                        Text(item.summary)
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if !item.description.isEmpty {
                                            Text(item.description)
                                                .font(.caption2)
                                                .italic()
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Text(item.displayPrice)
                                        .fontWeight(.medium)
                                }

                                if index < proposal.lineItems.count - 1 {
                                    Divider()
                                        .padding(.leading, 28)
                                }
                            }
                        }
                    }

                    // Pricing
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()

                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(formatCurrency(proposal.subtotal))
                        }

                        if proposal.discount > 0 {
                            HStack {
                                Text("Bundle Discount (\(Int(proposal.discount * 100))%)")
                                    .foregroundColor(.green)
                                Spacer()
                                Text("-\(formatCurrency(proposal.discountAmount))")
                                    .foregroundColor(.green)
                            }
                        }

                        HStack {
                            Text("Total")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            Text(formatCurrency(proposal.total))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical)
                        .padding(.horizontal)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Terms
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Terms & Conditions")
                            .font(.headline)

                        Text("Valid for \(proposal.validDays) days • 25% deposit required • Licensed & Insured")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            onSave()
                            dismiss()
                        }) {
                            Label("Save", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: { showShareSheet = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Proposal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [proposalText])
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

#Preview {
    ProposalBuilderV2View()
}