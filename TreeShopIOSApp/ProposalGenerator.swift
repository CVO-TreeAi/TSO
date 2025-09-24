import SwiftUI
import Foundation

// MARK: - Proposal Models

struct TreeAssessment: Identifiable {
    let id = UUID()
    var species: String = ""
    var height: Double = 0
    var dbh: Double = 0 // Diameter at Breast Height
    var canopySpread: Double = 0
    var condition: TreeCondition = .healthy

    var treeScore: Double {
        height + (dbh * 2) + canopySpread
    }

    enum TreeCondition: String, CaseIterable {
        case healthy = "Healthy"
        case diseased = "Diseased"
        case dead = "Dead"
        case hazardous = "Hazardous"
    }
}

struct AFISSMultiplier {
    var access: Double = 1.0
    var felling: Double = 1.0
    var infrastructure: Double = 1.0
    var slope: Double = 1.0
    var special: Double = 1.0

    var total: Double {
        access * felling * infrastructure * slope * special
    }

    static let accessOptions = [
        ("Easy - Open yard", 1.0),
        ("Medium - Some obstacles", 1.2),
        ("Hard - Tight space", 1.5)
    ]

    static let fellingOptions = [
        ("Open drop", 1.0),
        ("Sectional", 1.3),
        ("Technical rigging", 1.6)
    ]

    static let infrastructureOptions = [
        ("None nearby", 1.0),
        ("Some structures", 1.3),
        ("Critical/close", 1.5)
    ]

    static let slopeOptions = [
        ("Flat ground", 1.0),
        ("Moderate slope", 1.1),
        ("Steep slope", 1.3)
    ]

    static let specialOptions = [
        ("None", 1.0),
        ("Minor complications", 1.2),
        ("Major issues", 1.5)
    ]
}

struct ProposalPackage: Identifiable {
    let id = UUID()
    let name: String
    let baseMultiplier: Double
    let includes: [String]
    let popular: Bool
}

struct Proposal: Identifiable {
    let id = UUID()
    let customerName: String
    let address: String
    let date = Date()
    let validDays = 7

    var assessments: [TreeAssessment]
    var afiss: AFISSMultiplier
    var selectedService: ServiceType
    var selectedPackage: ProposalPackage

    var totalTreeScore: Double {
        assessments.reduce(0) { $0 + $1.treeScore }
    }

    var adjustedScore: Double {
        totalTreeScore * afiss.total
    }

    var estimatedHours: Double {
        adjustedScore / selectedService.pointsPerHour
    }

    var laborCost: Double {
        estimatedHours * selectedService.hourlyRate
    }

    var totalPrice: Double {
        laborCost * selectedPackage.baseMultiplier * 1.4 // 40% margin
    }

    enum ServiceType: String, CaseIterable {
        case removal = "Tree Removal"
        case trimming = "Tree Trimming"
        case stumpGrinding = "Stump Grinding"
        case emergency = "Emergency Service"

        var pointsPerHour: Double {
            switch self {
            case .removal: return 100
            case .trimming: return 120
            case .stumpGrinding: return 80
            case .emergency: return 50
            }
        }

        var hourlyRate: Double {
            switch self {
            case .removal: return 250
            case .trimming: return 225
            case .stumpGrinding: return 200
            case .emergency: return 400
            }
        }
    }
}

// MARK: - Pricing Calculator

class PricingCalculator: ObservableObject {
    @Published var assessments: [TreeAssessment] = [TreeAssessment()]
    @Published var afiss = AFISSMultiplier()
    @Published var selectedService: Proposal.ServiceType = .removal
    @Published var selectedPackageIndex = 1 // Default to recommended

    let removalPackages = [
        ProposalPackage(
            name: "Basic",
            baseMultiplier: 1.0,
            includes: ["Tree removal", "Debris cleanup", "Haul away"],
            popular: false
        ),
        ProposalPackage(
            name: "Complete",
            baseMultiplier: 1.25,
            includes: ["Everything in Basic", "Stump grinding", "Surface roots"],
            popular: true
        ),
        ProposalPackage(
            name: "Premium",
            baseMultiplier: 1.5,
            includes: ["Everything in Complete", "Deep grind", "Topsoil & seed", "Guarantee"],
            popular: false
        )
    ]

    let trimmingPackages = [
        ProposalPackage(
            name: "Maintenance",
            baseMultiplier: 1.0,
            includes: ["Deadwood removal", "Basic shaping", "Cleanup"],
            popular: false
        ),
        ProposalPackage(
            name: "Aesthetic",
            baseMultiplier: 1.3,
            includes: ["Crown cleaning", "Shape & balance", "Vista pruning"],
            popular: true
        ),
        ProposalPackage(
            name: "Health",
            baseMultiplier: 1.5,
            includes: ["Disease assessment", "Structural pruning", "Treatment plan"],
            popular: false
        )
    ]

    var currentPackages: [ProposalPackage] {
        switch selectedService {
        case .removal, .emergency:
            return removalPackages
        case .trimming:
            return trimmingPackages
        case .stumpGrinding:
            return removalPackages // Simplified for demo
        }
    }

    var currentProposal: Proposal {
        Proposal(
            customerName: "",
            address: "",
            assessments: assessments,
            afiss: afiss,
            selectedService: selectedService,
            selectedPackage: currentPackages[selectedPackageIndex]
        )
    }

    func addTree() {
        assessments.append(TreeAssessment())
    }

    func removeTree(at index: Int) {
        assessments.remove(at: index)
    }

    func generateQuickQuote() -> String {
        let p = currentProposal
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0

        return """
        TREESHOP INSTANT QUOTE

        Service: \(p.selectedService.rawValue)
        Trees: \(p.assessments.count)
        TreeScore: \(Int(p.totalTreeScore)) points
        Package: \(p.selectedPackage.name)

        Estimated Price: \(formatter.string(from: NSNumber(value: p.totalPrice)) ?? "$0")

        Valid for 7 days
        """
    }
}

// MARK: - Proposal Generator View

struct ProposalGeneratorView: View {
    @StateObject private var calculator = PricingCalculator()
    @State private var customerName = ""
    @State private var customerAddress = ""
    @State private var showingProposal = false

    var body: some View {
        NavigationStack {
            Form {
                // Customer Info
                Section("Customer Information") {
                    TextField("Customer Name", text: $customerName)
                    TextField("Property Address", text: $customerAddress)
                }

                // Tree Assessment
                Section("Tree Assessment") {
                    ForEach(calculator.assessments.indices, id: \.self) { index in
                        TreeAssessmentRow(assessment: $calculator.assessments[index])
                    }

                    Button(action: calculator.addTree) {
                        Label("Add Tree", systemImage: "plus.circle.fill")
                    }
                }

                // AFISS Multipliers
                AFISSSection(afiss: $calculator.afiss)

                // Service Selection
                Section("Service Type") {
                    Picker("Service", selection: $calculator.selectedService) {
                        ForEach(Proposal.ServiceType.allCases, id: \.self) { service in
                            Text(service.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Package Selection
                PackageSelectionSection(
                    packages: calculator.currentPackages,
                    selectedIndex: $calculator.selectedPackageIndex
                )

                // Pricing Summary
                PricingSummarySection(proposal: calculator.currentProposal)
            }
            .navigationTitle("Proposal Generator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate") {
                        showingProposal = true
                    }
                    .bold()
                }
            }
            .sheet(isPresented: $showingProposal) {
                ProposalView(
                    proposal: calculator.currentProposal,
                    customerName: customerName,
                    customerAddress: customerAddress
                )
            }
        }
    }
}

struct TreeAssessmentRow: View {
    @Binding var assessment: TreeAssessment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tree #")
                    .font(.headline)
                Spacer()
                Text("Score: \(Int(assessment.treeScore))")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }

            HStack {
                VStack {
                    Text("Height")
                        .font(.caption)
                    TextField("ft", value: $assessment.height, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }

                VStack {
                    Text("DBH")
                        .font(.caption)
                    TextField("in", value: $assessment.dbh, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }

                VStack {
                    Text("Canopy")
                        .font(.caption)
                    TextField("ft", value: $assessment.canopySpread, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
            }

            Picker("Condition", selection: $assessment.condition) {
                ForEach(TreeAssessment.TreeCondition.allCases, id: \.self) { condition in
                    Text(condition.rawValue).tag(condition)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.vertical, 4)
    }
}

struct AFISSSection: View {
    @Binding var afiss: AFISSMultiplier

    var body: some View {
        Section("AFISS Site Factors") {
            VStack(spacing: 12) {
                AFISSPicker(
                    title: "Access",
                    value: $afiss.access,
                    options: AFISSMultiplier.accessOptions
                )

                AFISSPicker(
                    title: "Felling",
                    value: $afiss.felling,
                    options: AFISSMultiplier.fellingOptions
                )

                AFISSPicker(
                    title: "Infrastructure",
                    value: $afiss.infrastructure,
                    options: AFISSMultiplier.infrastructureOptions
                )

                AFISSPicker(
                    title: "Slope",
                    value: $afiss.slope,
                    options: AFISSMultiplier.slopeOptions
                )

                AFISSPicker(
                    title: "Special",
                    value: $afiss.special,
                    options: AFISSMultiplier.specialOptions
                )

                HStack {
                    Text("Total Multiplier")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%.2fx", afiss.total))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(afiss.total > 1.5 ? .red : .green)
                }
                .padding(.top)
            }
        }
    }
}

struct AFISSPicker: View {
    let title: String
    @Binding var value: Double
    let options: [(String, Double)]

    var body: some View {
        HStack {
            Text(title)
                .frame(width: 100, alignment: .leading)

            Picker(title, selection: $value) {
                ForEach(options, id: \.1) { option in
                    Text(option.0).tag(option.1)
                }
            }
            .pickerStyle(MenuPickerStyle())

            Spacer()

            Text(String(format: "%.1fx", value))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct PackageSelectionSection: View {
    let packages: [ProposalPackage]
    @Binding var selectedIndex: Int

    var body: some View {
        Section("Service Package") {
            ForEach(packages.indices, id: \.self) { index in
                PackageOption(
                    package: packages[index],
                    isSelected: selectedIndex == index,
                    isRecommended: index == 1,
                    action: { selectedIndex = index }
                )
            }
        }
    }
}

struct PackageOption: View {
    let package: ProposalPackage
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(package.name)
                        .font(.headline)

                    if isRecommended {
                        Text("RECOMMENDED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                }

                ForEach(package.includes, id: \.self) { item in
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(item)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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

struct PricingSummarySection: View {
    let proposal: Proposal

    var body: some View {
        Section("Pricing Summary") {
            VStack(spacing: 12) {
                HStack {
                    Text("Total TreeScore")
                    Spacer()
                    Text("\(Int(proposal.totalTreeScore)) points")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("AFISS Adjusted")
                    Spacer()
                    Text("\(Int(proposal.adjustedScore)) points")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Estimated Hours")
                    Spacer()
                    Text(String(format: "%.1f hrs", proposal.estimatedHours))
                }

                Divider()

                HStack {
                    Text("Total Price")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "$%.0f", proposal.totalPrice))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                Text("Valid for 7 days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct ProposalView: View {
    let proposal: Proposal
    let customerName: String
    let customerAddress: String
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false

    var proposalText: String {
        """
        TREESHOP PROFESSIONAL SERVICES
        Proposal #\(Date().formatted(date: .numeric, time: .omitted))-001

        CUSTOMER: \(customerName)
        PROPERTY: \(customerAddress)
        DATE: \(Date().formatted(date: .abbreviated, time: .omitted))

        SERVICE: \(proposal.selectedService.rawValue)
        PACKAGE: \(proposal.selectedPackage.name)

        ASSESSMENT:
        • Trees: \(proposal.assessments.count)
        • Total TreeScore: \(Int(proposal.totalTreeScore)) points
        • Site Complexity: \(String(format: "%.1fx", proposal.afiss.total))

        INCLUDES:
        \(proposal.selectedPackage.includes.map { "✓ \($0)" }.joined(separator: "\n"))

        INVESTMENT: \(String(format: "$%.0f", proposal.totalPrice))

        Valid for 7 days from today

        Licensed & Insured | ISA Certified
        100% Satisfaction Guaranteed
        """
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(proposalText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)

                    HStack(spacing: 12) {
                        Button(action: { showShareSheet = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: { /* Copy action */ }) {
                            Label("Copy", systemImage: "doc.on.doc")
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
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ProposalGeneratorView()
}