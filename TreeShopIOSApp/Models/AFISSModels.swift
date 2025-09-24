import Foundation
import SwiftUI

// MARK: - AFISS Categories

enum AFISSCategory: String, CaseIterable {
    case structures = "Structures"
    case landscape = "Landscape"
    case utilities = "Utilities"
    case access = "Access"
    case projectSpecific = "Project"

    var fullName: String {
        switch self {
        case .structures: return "Structures & Infrastructure"
        case .landscape: return "Landscape & Aesthetic Features"
        case .utilities: return "Utilities & Services"
        case .access: return "Access & Site Conditions"
        case .projectSpecific: return "Project-Specific Factors"
        }
    }

    var icon: String {
        switch self {
        case .structures: return "building.2"
        case .landscape: return "leaf"
        case .utilities: return "bolt"
        case .access: return "arrow.triangle.2.circlepath"
        case .projectSpecific: return "wrench.and.screwdriver"
        }
    }

    var color: Color {
        switch self {
        case .structures: return .blue
        case .landscape: return .green
        case .utilities: return .orange
        case .access: return .purple
        case .projectSpecific: return .red
        }
    }
}

// MARK: - Assessment Factor Model

struct AssessmentFactor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: AFISSCategory
    let description: String
    let searchTerms: [String]
    let baseMultiplier: Double // Hidden percentage (e.g., 0.15 for 15%) - internal access only
    let impactType: ImpactType

    enum ImpactType {
        case score       // Affects TreeScore/StumpScore
        case production  // Affects PpH/iA-h
        case both       // Affects both
    }

    init(name: String, category: AFISSCategory, description: String, searchTerms: [String], baseMultiplier: Double, impactType: ImpactType) {
        self.name = name
        self.category = category
        self.description = description
        self.searchTerms = searchTerms
        self.baseMultiplier = baseMultiplier
        self.impactType = impactType
    }

    // Calculate AF Score based on base score
    func calculateScore(baseScore: Double) -> Int {
        return Int(baseScore * baseMultiplier)
    }

    // Get display percentage for internal use only (never show to customer)
    var internalPercentage: Int {
        return Int(baseMultiplier * 100)
    }

    // Create a selected version
    func selected() -> SelectedAssessmentFactor {
        return SelectedAssessmentFactor(factor: self)
    }
}

// MARK: - Selected Assessment Factor

struct SelectedAssessmentFactor: Identifiable, Hashable {
    let id = UUID()
    let factor: AssessmentFactor

    static func == (lhs: SelectedAssessmentFactor, rhs: SelectedAssessmentFactor) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Calculate AF Score dynamically based on provided base score
    func getAFScore(baseScore: Double) -> Int {
        return factor.calculateScore(baseScore: baseScore)
    }
}

// MARK: - AFISS Assessment Result

struct AFISSAssessment {
    var selectedFactors: [SelectedAssessmentFactor] = []

    // Total AF Score calculated dynamically based on provided base score
    func totalAFScore(baseScore: Double) -> Int {
        guard baseScore > 0 else { return 0 }
        return selectedFactors.reduce(0) { $0 + $1.getAFScore(baseScore: baseScore) }
    }

    // Internal multiplier for calculations (never exposed)
    var totalMultiplier: Double {
        let sumOfPercentages = selectedFactors.reduce(0.0) {
            $0 + $1.factor.baseMultiplier
        }
        return 1.0 + sumOfPercentages
    }

    // Get factors by category
    func factors(for category: AFISSCategory) -> [SelectedAssessmentFactor] {
        selectedFactors.filter { $0.factor.category == category }
    }

    // Add or remove a factor (no base score needed during selection)
    mutating func toggle(_ factor: AssessmentFactor) {
        if let index = selectedFactors.firstIndex(where: { $0.factor.id == factor.id }) {
            selectedFactors.remove(at: index)
        } else {
            selectedFactors.append(factor.selected())
        }
    }

    // Check if a factor is selected
    func isSelected(_ factor: AssessmentFactor) -> Bool {
        selectedFactors.contains { $0.factor.id == factor.id }
    }
}

// MARK: - AFISS Database

struct AFISSDatabase {
    static let assessmentFactors: [AssessmentFactor] = [
        // MARK: Category 1 - Structures & Infrastructure

        AssessmentFactor(
            name: "House/Building Proximity",
            category: .structures,
            description: "Structures within potential drop zone",
            searchTerms: ["house", "building", "home", "structure", "roof"],
            baseMultiplier: 0.15,
            impactType: .both
        ),
        AssessmentFactor(
            name: "Pool & Water Features",
            category: .structures,
            description: "Swimming pools, hot tubs, fountains",
            searchTerms: ["pool", "swimming", "hot tub", "spa", "fountain", "water feature"],
            baseMultiplier: 0.20,
            impactType: .score
        ),
        AssessmentFactor(
            name: "Deck & Patio",
            category: .structures,
            description: "Elevated surfaces and outdoor living areas",
            searchTerms: ["deck", "patio", "porch", "balcony", "terrace"],
            baseMultiplier: 0.12,
            impactType: .both
        ),
        AssessmentFactor(
            name: "Fencing",
            category: .structures,
            description: "Property boundaries and barriers",
            searchTerms: ["fence", "gate", "wall", "barrier", "boundary"],
            baseMultiplier: 0.08,
            impactType: .production
        ),
        AssessmentFactor(
            name: "Driveway & Walkways",
            category: .structures,
            description: "Paved surfaces requiring protection",
            searchTerms: ["driveway", "sidewalk", "walkway", "path", "pavement", "concrete"],
            baseMultiplier: 0.10,
            impactType: .production
        ),
        AssessmentFactor(
            name: "Outbuildings",
            category: .structures,
            description: "Sheds, garages, workshops",
            searchTerms: ["shed", "garage", "workshop", "barn", "outbuilding"],
            baseMultiplier: 0.12,
            impactType: .both
        ),

        // MARK: Category 2 - Landscape & Aesthetic Features

        AssessmentFactor(
            name: "Premium Lawn",
            category: .landscape,
            description: "Manicured or specialty grass areas",
            searchTerms: ["lawn", "grass", "turf", "yard", "zoysia", "bermuda"],
            baseMultiplier: 0.08,
            impactType: .production
        ),
        AssessmentFactor(
            name: "Garden Beds",
            category: .landscape,
            description: "Flower beds, vegetable gardens",
            searchTerms: ["garden", "flowers", "plants", "beds", "landscaping", "vegetables"],
            baseMultiplier: 0.10,
            impactType: .production
        ),
        AssessmentFactor(
            name: "Ornamental Trees/Shrubs",
            category: .landscape,
            description: "Specimen plants and shaped shrubs",
            searchTerms: ["shrubs", "bushes", "ornamental", "topiary", "specimen"],
            baseMultiplier: 0.12,
            impactType: .production
        ),
        AssessmentFactor(
            name: "Irrigation System",
            category: .landscape,
            description: "Sprinklers and underground irrigation",
            searchTerms: ["sprinkler", "irrigation", "watering", "drip"],
            baseMultiplier: 0.08,
            impactType: .production
        ),
        AssessmentFactor(
            name: "Hardscaping",
            category: .landscape,
            description: "Decorative stone, pavers, retaining walls",
            searchTerms: ["hardscape", "pavers", "stone", "brick", "retaining wall"],
            baseMultiplier: 0.15,
            impactType: .both
        ),

        // MARK: Category 3 - Utilities & Services

        AssessmentFactor(
            name: "Power Lines",
            category: .utilities,
            description: "Overhead electrical lines",
            searchTerms: ["power", "electric", "electrical", "lines", "wires", "voltage"],
            baseMultiplier: 0.30,
            impactType: .both
        ),
        AssessmentFactor(
            name: "Gas Lines",
            category: .utilities,
            description: "Natural gas or propane systems",
            searchTerms: ["gas", "propane", "natural gas", "fuel", "tank"],
            baseMultiplier: 0.25,
            impactType: .both
        ),
        AssessmentFactor(
            name: "Cable/Internet",
            category: .utilities,
            description: "Communication lines",
            searchTerms: ["cable", "internet", "phone", "fiber", "communication"],
            baseMultiplier: 0.12,
            impactType: .production
        ),
        AssessmentFactor(
            name: "Water/Sewer",
            category: .utilities,
            description: "Water mains, sewer lines, septic",
            searchTerms: ["water", "sewer", "septic", "plumbing", "pipes"],
            baseMultiplier: 0.18,
            impactType: .both
        ),
        AssessmentFactor(
            name: "HVAC Equipment",
            category: .utilities,
            description: "AC units, heat pumps, generators",
            searchTerms: ["ac", "hvac", "air conditioner", "heat pump", "generator"],
            baseMultiplier: 0.15,
            impactType: .production
        ),

        // MARK: Category 4 - Access & Site Conditions

        AssessmentFactor(
            name: "Narrow Access",
            category: .access,
            description: "Limited entry points or tight spaces",
            searchTerms: ["narrow", "tight", "limited", "small gate", "restricted"],
            baseMultiplier: 0.18,
            impactType: .production
        ),
        AssessmentFactor(
            name: "Steep Slope",
            category: .access,
            description: "Challenging terrain angles",
            searchTerms: ["steep", "slope", "hill", "incline", "grade"],
            baseMultiplier: 0.22,
            impactType: .both
        ),
        AssessmentFactor(
            name: "Backyard Location",
            category: .access,
            description: "Interior property position",
            searchTerms: ["backyard", "back yard", "rear", "behind house"],
            baseMultiplier: 0.12,
            impactType: .production
        ),
        AssessmentFactor(
            name: "Poor Ground Conditions",
            category: .access,
            description: "Wet, muddy, or unstable soil",
            searchTerms: ["mud", "wet", "soft", "saturated", "unstable", "swamp"],
            baseMultiplier: 0.15,
            impactType: .production
        ),
        AssessmentFactor(
            name: "Distance from Road",
            category: .access,
            description: "Long carry/drag distances",
            searchTerms: ["far", "distance", "remote", "carry", "drag"],
            baseMultiplier: 0.14,
            impactType: .production
        ),

        // MARK: Category 5 - Project-Specific Factors

        AssessmentFactor(
            name: "Dead/Diseased Tree",
            category: .projectSpecific,
            description: "Compromised tree structure",
            searchTerms: ["dead", "diseased", "dying", "decay", "rotten"],
            baseMultiplier: 0.20,
            impactType: .score
        ),
        AssessmentFactor(
            name: "Emergency/Storm",
            category: .projectSpecific,
            description: "Urgent or storm damage work",
            searchTerms: ["emergency", "storm", "urgent", "damage", "fallen"],
            baseMultiplier: 0.35,
            impactType: .both
        ),
        AssessmentFactor(
            name: "Permits Required",
            category: .projectSpecific,
            description: "Municipal approvals needed",
            searchTerms: ["permit", "approval", "city", "municipal", "hoa"],
            baseMultiplier: 0.15,
            impactType: .production
        ),
        AssessmentFactor(
            name: "Crane Required",
            category: .projectSpecific,
            description: "Specialized equipment needed",
            searchTerms: ["crane", "lift", "bucket", "specialized equipment"],
            baseMultiplier: 0.40,
            impactType: .both
        ),
        AssessmentFactor(
            name: "Historic/Protected",
            category: .projectSpecific,
            description: "Heritage or protected status",
            searchTerms: ["historic", "heritage", "protected", "landmark"],
            baseMultiplier: 0.25,
            impactType: .both
        )
    ]

    // Quick access by category
    static func factors(for category: AFISSCategory) -> [AssessmentFactor] {
        assessmentFactors.filter { $0.category == category }
    }

    // Search functionality
    static func search(query: String) -> [AssessmentFactor] {
        let lowercased = query.lowercased()
        guard !lowercased.isEmpty else { return [] }

        return assessmentFactors.filter { factor in
            // Search in name
            if factor.name.lowercased().contains(lowercased) {
                return true
            }
            // Search in description
            if factor.description.lowercased().contains(lowercased) {
                return true
            }
            // Search in search terms
            if factor.searchTerms.contains(where: { $0.contains(lowercased) }) {
                return true
            }
            return false
        }
    }

    // Scene analysis (suggests factors based on description)
    static func suggestFactors(from description: String) -> [AssessmentFactor] {
        let lowercased = description.lowercased()
        var suggestions: [(factor: AssessmentFactor, score: Int)] = []

        for factor in assessmentFactors {
            var matchScore = 0

            // Check each search term
            for term in factor.searchTerms {
                if lowercased.contains(term) {
                    matchScore += 10
                }
            }

            // Check name words
            for word in factor.name.lowercased().split(separator: " ") {
                if lowercased.contains(String(word)) {
                    matchScore += 5
                }
            }

            if matchScore > 0 {
                suggestions.append((factor, matchScore))
            }
        }

        // Sort by relevance and return top matches
        return suggestions
            .sorted { $0.score > $1.score }
            .prefix(10)
            .map { $0.factor }
    }
}