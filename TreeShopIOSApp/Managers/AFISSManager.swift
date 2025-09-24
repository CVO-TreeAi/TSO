import Foundation
import SwiftUI

@MainActor
class AFISSManager: ObservableObject {
    @Published var assessment = AFISSAssessment()
    @Published var searchText = ""
    @Published var selectedCategory: AFISSCategory? = nil
    @Published var isShowingAssessment = false
    @Published var sceneDescription = ""

    // Base score for calculating AF scores (from TreeScore, StumpScore, etc.)
    private var baseScore: Double = 100.0

    // Search results
    var searchResults: [AssessmentFactor] {
        if searchText.isEmpty {
            if let category = selectedCategory {
                return AFISSDatabase.factors(for: category)
            } else {
                return []
            }
        } else {
            return AFISSDatabase.search(query: searchText)
        }
    }

    // Suggested factors from scene description
    var suggestedFactors: [AssessmentFactor] {
        guard !sceneDescription.isEmpty else { return [] }
        return AFISSDatabase.suggestFactors(from: sceneDescription)
    }

    // All factors organized by category
    var factorsByCategory: [(category: AFISSCategory, factors: [AssessmentFactor])] {
        AFISSCategory.allCases.map { category in
            (category, AFISSDatabase.factors(for: category))
        }
    }

    // Initialize with a base score
    func initialize(baseScore: Double) {
        self.baseScore = baseScore
    }

    // Toggle a factor selection
    func toggleFactor(_ factor: AssessmentFactor) {
        assessment.toggle(factor)
    }

    // Check if factor is selected
    func isSelected(_ factor: AssessmentFactor) -> Bool {
        assessment.isSelected(factor)
    }

    // Get AF Score for a factor (what we show to users) - kept for compatibility but not shown during selection
    func getAFScore(for factor: AssessmentFactor) -> Int {
        factor.calculateScore(baseScore: baseScore)
    }

    // Clear all selections
    func clearAll() {
        assessment = AFISSAssessment()
    }

    // Apply suggested factors from scene description
    func applySuggestions() {
        for factor in suggestedFactors {
            if !isSelected(factor) {
                toggleFactor(factor)
            }
        }
        sceneDescription = ""
    }

    // Get summary for display
    func getSummary() -> String {
        if assessment.selectedFactors.isEmpty {
            return "No assessment factors selected"
        }

        let factorNames = assessment.selectedFactors
            .prefix(3)
            .map { $0.factor.name }
            .joined(separator: ", ")

        let more = assessment.selectedFactors.count > 3 ? " +\(assessment.selectedFactors.count - 3) more" : ""
        return "\(factorNames)\(more)"
    }

    // Get impact on final pricing (internal use only)
    func getPriceMultiplier() -> Double {
        assessment.totalMultiplier
    }

    // Get total AF Score (displayed to user) - dynamic based on base score
    func getTotalAFScore() -> Int {
        assessment.totalAFScore(baseScore: baseScore)
    }

    // Quick preset combinations
    func applyPreset(_ preset: AFISSPreset) {
        clearAll()
        for factorName in preset.factorNames {
            if let factor = AFISSDatabase.assessmentFactors.first(where: { $0.name == factorName }) {
                toggleFactor(factor)
            }
        }
    }
}

// MARK: - Preset Combinations

struct AFISSPreset {
    let name: String
    let description: String
    let factorNames: [String]

    static let presets = [
        AFISSPreset(
            name: "Suburban Standard",
            description: "Typical residential property",
            factorNames: ["House/Building Proximity", "Premium Lawn", "Driveway & Walkways"]
        ),
        AFISSPreset(
            name: "Luxury Estate",
            description: "High-value property with extensive landscaping",
            factorNames: ["Pool & Water Features", "Premium Lawn", "Garden Beds", "Hardscaping", "Irrigation System"]
        ),
        AFISSPreset(
            name: "Tight Access",
            description: "Challenging backyard access",
            factorNames: ["Narrow Access", "Backyard Location", "Fencing"]
        ),
        AFISSPreset(
            name: "Utility Hazard",
            description: "Power lines and utilities present",
            factorNames: ["Power Lines", "Cable/Internet", "HVAC Equipment"]
        ),
        AFISSPreset(
            name: "Emergency Storm",
            description: "Storm damage emergency work",
            factorNames: ["Emergency/Storm", "Dead/Diseased Tree", "House/Building Proximity"]
        )
    ]
}