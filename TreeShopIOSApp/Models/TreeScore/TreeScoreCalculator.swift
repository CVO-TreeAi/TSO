import Foundation
import CoreLocation

// MARK: - TreeScore Calculator for Full Ops Pricing
// Integrates TreeScore with comprehensive pricing methods and workflows

struct TreeScoreCalculator {

    // MARK: - TreeScore Calculation
    static func calculateTreeScore(
        height: Double,
        canopyRadius: Double,
        dbh: Double,
        afissPercentage: Double,
        gpsAccuracy: CLLocationAccuracy? = nil
    ) -> TreeScoreResult {

        // Base calculations
        let canopyArea = Double.pi * pow(canopyRadius, 2)
        let baseScore = (height * canopyArea * dbh) / 100.0

        // AFISS impact (hazard scoring)
        let afissMultiplier = 1.0 + (afissPercentage / 100.0)
        let hazardImpact = baseScore * (afissMultiplier - 1.0)

        // Final TreeScore
        let finalTreeScore = baseScore * afissMultiplier

        // Formula documentation
        let formula = "TreeScore = ((H × πR² × DBH) / 100) × (1 + AFISS%/100)"

        // Validation
        let isValid = height > 0 && canopyRadius > 0 && dbh > 0 && afissPercentage >= 0 && afissPercentage <= 100

        return TreeScoreResult(
            baseScore: baseScore,
            hazardImpact: hazardImpact,
            finalTreeScore: finalTreeScore,
            formula: formula,
            isValid: isValid,
            gpsAccuracy: gpsAccuracy
        )
    }

    // MARK: - Ops Pricing Calculation
    static func calculateOpsPrice(
        treeScore: Double,
        serviceType: ServiceType,
        crewSize: Int,
        equipmentType: EquipmentType,
        includesCleanup: Bool,
        includesHauling: Bool,
        urgencyFactor: UrgencyFactor = .normal
    ) -> OpsPricingResult {

        // Base hourly rates by equipment type
        let baseHourlyRate: Double
        switch equipmentType {
        case .manual:
            baseHourlyRate = 150.0
        case .smallChipper:
            baseHourlyRate = 250.0
        case .largeChipper:
            baseHourlyRate = 350.0
        case .crane:
            baseHourlyRate = 500.0
        case .bucket:
            baseHourlyRate = 450.0
        case .mulcher:
            baseHourlyRate = 600.0
        }

        // Crew PpH (Points per Hour) based on crew size and equipment
        let basePpH = 50.0 // Base points per hour for single climber
        let crewMultiplier = 1.0 + (Double(crewSize - 1) * 0.3) // 30% efficiency gain per additional crew
        let equipmentMultiplier = equipmentType.efficiencyMultiplier
        let effectivePpH = basePpH * crewMultiplier * equipmentMultiplier

        // Calculate time required
        let baseTimeHours = treeScore / effectivePpH

        // Service type multipliers
        let serviceMultiplier = serviceType.priceMultiplier

        // Calculate base price
        var basePrice = baseTimeHours * baseHourlyRate * serviceMultiplier

        // Add cleanup cost if included
        if includesCleanup {
            basePrice += basePrice * 0.15 // 15% additional for cleanup
        }

        // Add hauling cost if included
        if includesHauling {
            basePrice += basePrice * 0.20 // 20% additional for hauling
        }

        // Apply urgency factor
        let finalPrice = basePrice * urgencyFactor.multiplier

        // Calculate profit margin
        let laborCost = baseTimeHours * Double(crewSize) * 35.0 // $35/hour per crew member
        let equipmentCost = baseTimeHours * equipmentType.hourlyOperatingCost
        let totalCost = laborCost + equipmentCost
        let profitMargin = (finalPrice - totalCost) / finalPrice

        return OpsPricingResult(
            treeScore: treeScore,
            estimatedHours: baseTimeHours,
            basePrice: basePrice,
            finalPrice: finalPrice,
            laborCost: laborCost,
            equipmentCost: equipmentCost,
            profitMargin: profitMargin,
            effectivePpH: effectivePpH
        )
    }

    // MARK: - Bulk Property Pricing
    static func calculatePropertyPrice(
        trees: [TreeInventoryItem],
        serviceType: ServiceType,
        defaultCrewSize: Int,
        defaultEquipment: EquipmentType,
        includesCleanup: Bool = true,
        includesHauling: Bool = false,
        bulkDiscount: Double = 0.0
    ) -> PropertyPricingResult {

        var totalTreeScore = 0.0
        var treeDetails: [TreePricingDetail] = []

        // Calculate individual tree prices
        for tree in trees {
            let pricing = calculateOpsPrice(
                treeScore: tree.treeScore.finalTreeScore,
                serviceType: serviceType,
                crewSize: defaultCrewSize,
                equipmentType: defaultEquipment,
                includesCleanup: includesCleanup,
                includesHauling: includesHauling
            )

            totalTreeScore += tree.treeScore.finalTreeScore

            treeDetails.append(TreePricingDetail(
                treeId: tree.id,
                species: tree.species ?? "Unknown",
                treeScore: tree.treeScore.finalTreeScore,
                estimatedHours: pricing.estimatedHours,
                price: pricing.finalPrice
            ))
        }

        // Calculate totals
        let totalPrice = treeDetails.reduce(0) { $0 + $1.price }
        let totalHours = treeDetails.reduce(0) { $0 + $1.estimatedHours }

        // Apply bulk discount
        let discountAmount = totalPrice * bulkDiscount
        let finalPrice = totalPrice - discountAmount

        // Calculate scheduling
        let crewDaysRequired = ceil(totalHours / 8.0) // 8-hour work days
        let recommendedCrewSize = totalHours > 40 ? 3 : (totalHours > 16 ? 2 : 1)

        return PropertyPricingResult(
            totalTrees: trees.count,
            totalTreeScore: totalTreeScore,
            totalHours: totalHours,
            subtotal: totalPrice,
            discount: discountAmount,
            finalPrice: finalPrice,
            crewDaysRequired: Int(crewDaysRequired),
            recommendedCrewSize: recommendedCrewSize,
            treeDetails: treeDetails
        )
    }
}

// MARK: - Supporting Types

enum ServiceType: String, CaseIterable {
    case pruning = "Pruning"
    case removal = "Removal"
    case thinning = "Thinning"
    case clearing = "Clearing"
    case emergency = "Emergency"

    var priceMultiplier: Double {
        switch self {
        case .pruning: return 0.8
        case .removal: return 1.0
        case .thinning: return 0.6
        case .clearing: return 0.7
        case .emergency: return 1.5
        }
    }
}

enum EquipmentType: String, CaseIterable {
    case manual = "Manual/Climbing"
    case smallChipper = "Small Chipper"
    case largeChipper = "Large Chipper"
    case crane = "Crane"
    case bucket = "Bucket Truck"
    case mulcher = "Mulcher"

    var efficiencyMultiplier: Double {
        switch self {
        case .manual: return 1.0
        case .smallChipper: return 1.3
        case .largeChipper: return 1.5
        case .crane: return 2.0
        case .bucket: return 1.8
        case .mulcher: return 2.5
        }
    }

    var hourlyOperatingCost: Double {
        switch self {
        case .manual: return 20
        case .smallChipper: return 50
        case .largeChipper: return 80
        case .crane: return 200
        case .bucket: return 150
        case .mulcher: return 250
        }
    }
}

enum UrgencyFactor: String, CaseIterable {
    case normal = "Normal"
    case priority = "Priority"
    case emergency = "Emergency"
    case storm = "Storm Response"

    var multiplier: Double {
        switch self {
        case .normal: return 1.0
        case .priority: return 1.25
        case .emergency: return 1.5
        case .storm: return 2.0
        }
    }
}

// MARK: - Result Types

struct TreeScoreResult {
    let baseScore: Double
    let hazardImpact: Double
    let finalTreeScore: Double
    let formula: String
    let isValid: Bool
    let gpsAccuracy: CLLocationAccuracy?
    let calculationDate: Date

    init(baseScore: Double, hazardImpact: Double, finalTreeScore: Double,
         formula: String, isValid: Bool, gpsAccuracy: CLLocationAccuracy? = nil) {
        self.baseScore = baseScore
        self.hazardImpact = hazardImpact
        self.finalTreeScore = finalTreeScore
        self.formula = formula
        self.isValid = isValid
        self.gpsAccuracy = gpsAccuracy
        self.calculationDate = Date()
    }
}

struct OpsPricingResult {
    let treeScore: Double
    let estimatedHours: Double
    let basePrice: Double
    let finalPrice: Double
    let laborCost: Double
    let equipmentCost: Double
    let profitMargin: Double
    let effectivePpH: Double
}

struct PropertyPricingResult {
    let totalTrees: Int
    let totalTreeScore: Double
    let totalHours: Double
    let subtotal: Double
    let discount: Double
    let finalPrice: Double
    let crewDaysRequired: Int
    let recommendedCrewSize: Int
    let treeDetails: [TreePricingDetail]
}

struct TreePricingDetail {
    let treeId: UUID
    let species: String
    let treeScore: Double
    let estimatedHours: Double
    let price: Double
}