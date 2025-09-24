import Foundation
import CoreLocation
import MapKit
import CoreData

// MARK: - Tree Inventory Item
// GPS-located tree with TreeScore calculation and Ops integration

class TreeInventoryItem: NSObject, MKAnnotation {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let gpsAccuracy: CLLocationAccuracy

    // Tree Measurements
    let height: Double
    let canopyRadius: Double
    let dbh: Double
    let afissPercentage: Double

    // TreeScore Results
    let treeScore: TreeScoreResult
    var opsPricing: OpsPricingResult?

    // Metadata
    let species: String?
    let healthStatus: String?
    let hazardType: HazardType?
    let notes: String?
    let dateCreated: Date
    let createdBy: String?
    let photos: [Data]?

    // MKAnnotation properties
    var title: String? {
        return species ?? "Tree #\(id.uuidString.prefix(8))"
    }

    var subtitle: String? {
        let scoreText = String(format: "TreeScore: %.1f", treeScore.finalTreeScore)
        if let pricing = opsPricing {
            let priceText = String(format: "$%.0f", pricing.finalPrice)
            return "\(scoreText) • \(priceText)"
        }
        return scoreText
    }

    init(id: UUID = UUID(),
         coordinate: CLLocationCoordinate2D,
         gpsAccuracy: CLLocationAccuracy,
         height: Double,
         canopyRadius: Double,
         dbh: Double,
         afissPercentage: Double,
         species: String? = nil,
         healthStatus: String? = nil,
         hazardType: HazardType? = nil,
         notes: String? = nil,
         photos: [Data]? = nil,
         createdBy: String? = nil) {

        self.id = id
        self.coordinate = coordinate
        self.gpsAccuracy = gpsAccuracy
        self.height = height
        self.canopyRadius = canopyRadius
        self.dbh = dbh
        self.afissPercentage = afissPercentage
        self.species = species
        self.healthStatus = healthStatus
        self.hazardType = hazardType
        self.notes = notes
        self.photos = photos
        self.dateCreated = Date()
        self.createdBy = createdBy

        // Calculate TreeScore
        self.treeScore = TreeScoreCalculator.calculateTreeScore(
            height: height,
            canopyRadius: canopyRadius,
            dbh: dbh,
            afissPercentage: afissPercentage,
            gpsAccuracy: gpsAccuracy
        )

        super.init()
    }

    // Calculate ops pricing for this tree
    func calculateOpsPrice(
        serviceType: ServiceType,
        crewSize: Int,
        equipmentType: EquipmentType,
        includesCleanup: Bool,
        includesHauling: Bool,
        urgencyFactor: UrgencyFactor = .normal
    ) {
        self.opsPricing = TreeScoreCalculator.calculateOpsPrice(
            treeScore: treeScore.finalTreeScore,
            serviceType: serviceType,
            crewSize: crewSize,
            equipmentType: equipmentType,
            includesCleanup: includesCleanup,
            includesHauling: includesHauling,
            urgencyFactor: urgencyFactor
        )
    }

    // Get complexity level for visual representation
    var complexity: TreeComplexity {
        switch treeScore.finalTreeScore {
        case 0..<50:
            return .low
        case 50..<150:
            return .medium
        case 150..<300:
            return .high
        default:
            return .extreme
        }
    }

    // Get risk assessment
    var riskLevel: RiskLevel {
        if let hazard = hazardType {
            switch hazard {
            case .powerLines, .structure:
                return .high
            case .road:
                return .medium
            case .none:
                return healthStatus == "Dead" || healthStatus == "Dying" ? .medium : .low
            }
        }
        return .low
    }
}

// MARK: - Supporting Types

enum TreeComplexity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case extreme = "Extreme"

    var color: String {
        switch self {
        case .low: return "#00C853"      // Green
        case .medium: return "#FFB300"    // Orange
        case .high: return "#FF3D00"      // Red
        case .extreme: return "#AA00FF"   // Purple
        }
    }

    var iconName: String {
        switch self {
        case .low: return "leaf.fill"
        case .medium: return "tree.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .extreme: return "flame.fill"
        }
    }
}

enum HazardType: String, CaseIterable {
    case none = "None"
    case powerLines = "Power Lines"
    case structure = "Structure"
    case road = "Road"

    var afissAddition: Double {
        switch self {
        case .none: return 0
        case .road: return 10
        case .structure: return 20
        case .powerLines: return 30
        }
    }
}

enum RiskLevel: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: String {
        switch self {
        case .low: return "#4CAF50"
        case .medium: return "#FFC107"
        case .high: return "#F44336"
        }
    }
}

enum TreeHealth: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case dying = "Dying"
    case dead = "Dead"

    var healthMultiplier: Double {
        switch self {
        case .excellent: return 0.9
        case .good: return 1.0
        case .fair: return 1.1
        case .poor: return 1.2
        case .dying: return 1.3
        case .dead: return 1.4
        }
    }
}

// MARK: - Extensions for Core Data Integration

extension TreeInventoryItem {

    // Convert to Core Data entity
    func toCoreDataEntity(context: NSManagedObjectContext) -> CDTree? {
        // This would create a CDTree entity with all the properties
        // Implementation depends on your Core Data model
        return nil
    }

    // Create from Core Data entity
    static func fromCoreDataEntity(_ cdTree: CDTree) -> TreeInventoryItem? {
        // This would convert from CDTree entity back to TreeInventoryItem
        // Implementation depends on your Core Data model
        return nil
    }

    // Export to JSON
    func toJSON() -> [String: Any] {
        return [
            "id": id.uuidString,
            "coordinate": [
                "latitude": coordinate.latitude,
                "longitude": coordinate.longitude
            ],
            "gpsAccuracy": gpsAccuracy,
            "height": height,
            "canopyRadius": canopyRadius,
            "dbh": dbh,
            "afissPercentage": afissPercentage,
            "treeScore": treeScore.finalTreeScore,
            "species": species ?? "",
            "healthStatus": healthStatus ?? "",
            "hazardType": hazardType?.rawValue ?? "",
            "notes": notes ?? "",
            "dateCreated": dateCreated.timeIntervalSince1970,
            "createdBy": createdBy ?? ""
        ]
    }
}

// Placeholder for CDTree entity - would be generated by Core Data
class CDTree: NSManagedObject {
    // Core Data properties would be defined here
}