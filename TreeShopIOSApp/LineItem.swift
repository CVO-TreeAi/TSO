import Foundation
import SwiftUI

enum ServiceCategory: String, CaseIterable, Identifiable {
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

    var id: String { rawValue }

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

    var color: Color {
        switch self {
        case .treeRemoval: return .green
        case .treeTrimming: return .blue
        case .stumpGrinding: return .brown
        case .forestryMulching: return .orange
        case .emergency: return .red
        case .landClearing: return .purple
        case .craneRemoval: return .cyan
        case .healthAssessment: return .mint
        case .woodRetention: return .indigo
        case .rightOfWay: return .yellow
        }
    }
}

struct LineItem: Identifiable {
    let id = UUID()
    let category: ServiceCategory
    let name: String
    let description: String
    let unitOfMeasurement: String
    let rateCalculation: String
    let inclusions: [String]
    let exclusions: [String]
    let packages: [ServicePackage]?
}

struct ServicePackage: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let details: String
}

class LineItemsData: ObservableObject {
    @Published var items: [LineItem] = []

    init() {
        loadLineItems()
    }

    func loadLineItems() {
        items = [
            LineItem(
                category: .treeRemoval,
                name: "Tree Removal - Complete Extraction Service",
                description: "Professional removal of trees from ground level, including complete extraction of trunk and major branches. Service includes controlled sectioning, rigging for property protection, complete debris cleanup, and site restoration to pre-work condition.",
                unitOfMeasurement: "TreeScore Points",
                rateCalculation: "Base TreeScore × AFISS Multiplier ÷ Crew PpH = Work Hours × Loadout Rate",
                inclusions: [
                    "Complete tree removal from ground level",
                    "Professional rigging and controlled lowering",
                    "Major branch sectioning and removal",
                    "Complete debris cleanup and removal from property",
                    "Site restoration to reasonable pre-work condition",
                    "Wood chipping and hauling (unless customer retention requested)"
                ],
                exclusions: [
                    "Stump grinding (separate line item)",
                    "Root system removal (separate specialty service)",
                    "Permit acquisition (customer responsibility)",
                    "Utility line work (requires specialized certification)"
                ],
                packages: nil
            ),

            LineItem(
                category: .treeTrimming,
                name: "Tree Trimming - Precision Pruning Service",
                description: "Selective removal of branches and foliage following ISA pruning standards to improve tree health, safety, aesthetics, or achieve clearance requirements.",
                unitOfMeasurement: "TreeScore Points (adjusted by trimming percentage)",
                rateCalculation: "(Base TreeScore × Trimming %) × AFISS Multiplier ÷ Crew PpH = Work Hours × Loadout Rate",
                inclusions: [
                    "Professional assessment and pruning plan",
                    "ISA-standard pruning cuts for tree health",
                    "Selective branch removal per agreed percentage",
                    "Complete debris removal and disposal",
                    "Site cleanup to pre-work condition"
                ],
                exclusions: [
                    "Emergency storm work (separate service)",
                    "Cabling and bracing (structural support service)",
                    "Disease treatment applications",
                    "Root pruning or trenching"
                ],
                packages: [
                    ServicePackage(name: "Light Trim (5-15%)", description: "Basic maintenance", details: "Deadwood removal, sucker cleaning, minor shaping"),
                    ServicePackage(name: "Moderate Trim (15-25%)", description: "Standard pruning", details: "Crown cleaning, clearance pruning, structural improvements"),
                    ServicePackage(name: "Heavy Trim (25-40%)", description: "Major work", details: "Crown reduction, restoration pruning, major clearance"),
                    ServicePackage(name: "Severe Trim (40%+)", description: "Extensive pruning", details: "Major reduction, storm preparation, utility clearance")
                ]
            ),

            LineItem(
                category: .stumpGrinding,
                name: "Stump Grinding - Below-Grade Removal",
                description: "Mechanical removal of tree stumps using specialized grinding equipment, reducing stumps and major surface roots to wood chips below specified grade level.",
                unitOfMeasurement: "StumpScore Points",
                rateCalculation: "StumpScore (Height + Depth × DBH) × AFISS ÷ Equipment PpH = Hours × Equipment Rate",
                inclusions: [
                    "Stump removal to specified depth",
                    "Major surface root grinding within equipment reach",
                    "Wood chip management (spread or removal)",
                    "Access route cleanup and protection",
                    "Basic hole backfill with grindings"
                ],
                exclusions: [
                    "Complete root system removal",
                    "Soil replacement or grading",
                    "Grass seeding or sod installation",
                    "Underground utility repairs"
                ],
                packages: [
                    ServicePackage(name: "Basic (6\" depth)", description: "Simple elimination", details: "Simple stump elimination for mowing"),
                    ServicePackage(name: "Standard (8\" depth)", description: "Typical residential", details: "Typical residential application"),
                    ServicePackage(name: "Deep (12\" depth)", description: "Landscaping prep", details: "Preparation for replanting or landscaping"),
                    ServicePackage(name: "Maximum (18\"+ depth)", description: "Construction prep", details: "Construction or foundation preparation")
                ]
            ),

            LineItem(
                category: .forestryMulching,
                name: "Forestry Mulching - Land Clearing Package",
                description: "Specialized land clearing using forestry mulching equipment to cut, grind, and spread vegetation in place. Creates natural erosion-preventing mulch layer while preserving soil structure.",
                unitOfMeasurement: "Inch-Acres (DBH inches × acres cleared)",
                rateCalculation: "(Package DBH × Acres) ÷ Production Rate = Mulching Hours × Equipment Rate",
                inclusions: [
                    "Complete mulching of all vegetation up to package DBH limit",
                    "Even distribution of mulch across cleared area",
                    "Minimal soil disturbance and root preservation",
                    "Natural erosion control through mulch layer",
                    "Basic site preparation for future use"
                ],
                exclusions: [
                    "Trees exceeding package DBH limit",
                    "Non-vegetative debris removal",
                    "Grading or soil work",
                    "Permit acquisition",
                    "Stump grinding of existing stumps"
                ],
                packages: [
                    ServicePackage(name: "Small (4\" max)", description: "Light clearing", details: "Light brush, saplings, understory vegetation"),
                    ServicePackage(name: "Medium (6\" max)", description: "Moderate clearing", details: "Small trees, dense brush, heavy undergrowth"),
                    ServicePackage(name: "Large (8\" max)", description: "Heavy clearing", details: "Mature understory, medium tree removal"),
                    ServicePackage(name: "XL (10\" max)", description: "Comprehensive", details: "Comprehensive clearing, large vegetation"),
                    ServicePackage(name: "Max (12\"+ max)", description: "Maximum capability", details: "Maximum capability clearing")
                ]
            ),

            LineItem(
                category: .emergency,
                name: "Emergency Response - 24/7 Tree Service",
                description: "Immediate response for storm-damaged, fallen, or hazardous trees posing imminent danger to life or property. Premium service with expedited response times.",
                unitOfMeasurement: "Emergency Response Hours",
                rateCalculation: "Emergency TreeScore × 1.5-2.0 multiplier × Emergency Rate",
                inclusions: [
                    "Immediate hazard assessment",
                    "Emergency stabilization or removal",
                    "Coordination with utilities/emergency services",
                    "Critical debris clearing for access",
                    "Insurance documentation and photos",
                    "Temporary protective measures"
                ],
                exclusions: [],
                packages: [
                    ServicePackage(name: "Priority 1", description: "Critical emergency", details: "Tree on structure, blocking emergency access"),
                    ServicePackage(name: "Priority 2", description: "High risk", details: "Imminent failure risk, power line involvement"),
                    ServicePackage(name: "Priority 3", description: "Property risk", details: "Property damage risk, access impediment"),
                    ServicePackage(name: "Priority 4", description: "Preventive", details: "Preventive removal before storm")
                ]
            ),

            LineItem(
                category: .landClearing,
                name: "Complete Lot Clearing - Development Preparation",
                description: "Comprehensive clearing of designated areas for construction, development, or land use change. Combines selective tree removal, undergrowth clearing, and site preparation.",
                unitOfMeasurement: "Project Days or Acres",
                rateCalculation: "Daily Rate: Equipment + Crew + Overhead × Margin",
                inclusions: [
                    "Complete vegetation removal per specifications",
                    "Selective tree preservation marking if required",
                    "Debris processing (chip, haul, or mulch)",
                    "Basic erosion control measures",
                    "Site access preparation"
                ],
                exclusions: [],
                packages: [
                    ServicePackage(name: "Removal Method", description: "Complete extraction", details: "Complete extraction and hauling"),
                    ServicePackage(name: "Mulching Method", description: "In-place processing", details: "In-place grinding and spreading"),
                    ServicePackage(name: "Hybrid Method", description: "Combined approach", details: "Selective removal with undergrowth mulching"),
                    ServicePackage(name: "Selective Method", description: "Preservation focus", details: "Preserve designated trees, clear remainder")
                ]
            ),

            LineItem(
                category: .craneRemoval,
                name: "Technical Crane Removal - Complex Extraction",
                description: "Specialized removal service utilizing crane equipment for trees in extremely confined spaces, over structures, or requiring precision placement.",
                unitOfMeasurement: "TreeScore Points + Crane Hours",
                rateCalculation: "(TreeScore × Technical Multiplier) + (Crane Hours × Crane Rate)",
                inclusions: [
                    "Engineering and lift plan development",
                    "Crane delivery, setup, and operation",
                    "Certified crane operator and signal person",
                    "Specialized rigging and hardware",
                    "Coordinated removal operations",
                    "Standard cleanup and hauling"
                ],
                exclusions: [],
                packages: nil
            ),

            LineItem(
                category: .healthAssessment,
                name: "Certified Arborist Assessment - Health Evaluation",
                description: "Professional evaluation of tree health, structure, and risk by ISA Certified Arborist. Includes detailed inspection, risk assessment rating, treatment recommendations, and written report.",
                unitOfMeasurement: "Per Tree or Hourly Assessment",
                rateCalculation: "Base Assessment Fee + (Number of Trees × Per-Tree Rate)",
                inclusions: [
                    "Certified Arborist inspection",
                    "Tree health and structure evaluation",
                    "Risk assessment rating",
                    "TreeScore calculation and documentation",
                    "Written recommendations",
                    "Follow-up consultation"
                ],
                exclusions: [],
                packages: [
                    ServicePackage(name: "Basic", description: "Visual assessment", details: "Visual assessment with verbal report"),
                    ServicePackage(name: "Standard", description: "Written report", details: "Written report with recommendations"),
                    ServicePackage(name: "Comprehensive", description: "Full documentation", details: "Detailed report with TreeScore, photos, treatment plan"),
                    ServicePackage(name: "Legal/Insurance", description: "Court-admissible", details: "Court-admissible documentation with certified report")
                ]
            ),

            LineItem(
                category: .woodRetention,
                name: "Customer Wood Retention - Processing Options",
                description: "Processing and preparation of wood materials for customer retention. Options include cutting to specified firewood lengths, stacking at designated location, or leaving trunk sections for milling.",
                unitOfMeasurement: "Processing Hours or Cord Production",
                rateCalculation: "TreeScore Base - Hauling Credit + Processing Time × Rate",
                inclusions: [
                    "Wood cutting to specified dimensions",
                    "Movement to designated location on property",
                    "Basic stacking or organization",
                    "Separation of premium wood if requested"
                ],
                exclusions: [],
                packages: [
                    ServicePackage(name: "Firewood Cut", description: "Rounds only", details: "Rounds cut to 16-18\" lengths"),
                    ServicePackage(name: "Firewood Split", description: "Cut and split", details: "Cut and split to size"),
                    ServicePackage(name: "Stacking Service", description: "Organized stacking", details: "Organized stacking at location"),
                    ServicePackage(name: "Milling Prep", description: "Sawmill ready", details: "Trunk sections prepared for sawmill"),
                    ServicePackage(name: "Rough Bucking", description: "Large sections", details: "Large sections for customer processing")
                ]
            ),

            LineItem(
                category: .rightOfWay,
                name: "Utility & Access Corridor Maintenance",
                description: "Systematic clearing and maintenance of utility corridors, easements, and access routes. Service ensures compliance with utility standards and regulations while maintaining required clearances.",
                unitOfMeasurement: "Linear Feet or Corridor Acres",
                rateCalculation: "(Linear Feet × Width × Vegetation Density Factor) ÷ ROW PpH",
                inclusions: [
                    "Vegetation assessment and planning",
                    "Selective removal to specifications",
                    "Compliant disposal methods",
                    "Regrowth treatment (if contracted)",
                    "Compliance documentation"
                ],
                exclusions: [],
                packages: [
                    ServicePackage(name: "Distribution Lines", description: "10-15 ft clearance", details: "10-15 foot clearance"),
                    ServicePackage(name: "Transmission Lines", description: "20-30 ft clearance", details: "20-30 foot clearance"),
                    ServicePackage(name: "Access Roads", description: "Road clearance", details: "14-16 foot width, 14 foot height"),
                    ServicePackage(name: "Pipeline Corridors", description: "Easement width", details: "Specified easement width")
                ]
            )
        ]
    }
}