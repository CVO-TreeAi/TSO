import Foundation
import SwiftUI

// MARK: - Equipment Models

enum EquipmentCategory: String, CaseIterable, Codable, Identifiable {
    case bucketTruck = "Bucket Truck"
    case chipper = "Chipper"
    case stumpGrinder = "Stump Grinder"
    case dumpTruck = "Dump Truck"
    case pickupTruck = "Pickup Truck"
    case trailer = "Trailer"
    case forestryMulcher = "Forestry Mulcher"
    case crane = "Crane"
    case miniExcavator = "Mini Excavator"
    case chainsaw = "Chainsaw"
    case climbingGear = "Climbing Gear"
    case riggingEquipment = "Rigging Equipment"
    case handTools = "Hand Tools"
    case safetyGear = "Safety Gear"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .bucketTruck: return "arrow.up.to.line"
        case .chipper: return "circle.grid.3x3.fill"
        case .stumpGrinder: return "circle.dashed"
        case .dumpTruck: return "truck.box.fill"
        case .pickupTruck: return "car.fill"
        case .trailer: return "rectangle.connected.to.line.below"
        case .forestryMulcher: return "square.grid.3x3.fill.square"
        case .crane: return "crane.fill"
        case .miniExcavator: return "wrench.and.screwdriver.fill"
        case .chainsaw: return "scissors"
        case .climbingGear: return "figure.climbing"
        case .riggingEquipment: return "link"
        case .handTools: return "hammer.fill"
        case .safetyGear: return "shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .bucketTruck, .crane: return .blue
        case .chipper, .stumpGrinder, .forestryMulcher: return .orange
        case .dumpTruck, .pickupTruck, .trailer: return .green
        case .miniExcavator: return .purple
        case .chainsaw, .handTools: return .red
        case .climbingGear, .riggingEquipment: return .brown
        case .safetyGear: return .yellow
        }
    }

    // Default values for predictive UI
    var defaultValues: EquipmentDefaults {
        switch self {
        case .bucketTruck:
            return EquipmentDefaults(
                purchasePrice: 165000,
                salvagePercentage: 30,
                expectedLifeHours: 10000,
                fuelBurnGPH: 6.5,
                maintenanceFactor: 60,
                insuranceRate: 3,
                annualHours: 2000
            )
        case .chipper:
            return EquipmentDefaults(
                purchasePrice: 50000,
                salvagePercentage: 25,
                expectedLifeHours: 5000,
                fuelBurnGPH: 2.5,
                maintenanceFactor: 90,
                insuranceRate: 3,
                annualHours: 1800
            )
        case .stumpGrinder:
            return EquipmentDefaults(
                purchasePrice: 45000,
                salvagePercentage: 25,
                expectedLifeHours: 5000,
                fuelBurnGPH: 2.8,
                maintenanceFactor: 90,
                insuranceRate: 3,
                annualHours: 1600
            )
        case .forestryMulcher:
            return EquipmentDefaults(
                purchasePrice: 118000,
                salvagePercentage: 20,
                expectedLifeHours: 6000,
                fuelBurnGPH: 5.5,
                maintenanceFactor: 100,
                insuranceRate: 4,
                annualHours: 1800
            )
        case .dumpTruck:
            return EquipmentDefaults(
                purchasePrice: 85000,
                salvagePercentage: 35,
                expectedLifeHours: 8000,
                fuelBurnGPH: 4.0,
                maintenanceFactor: 50,
                insuranceRate: 3,
                annualHours: 2000
            )
        case .pickupTruck:
            return EquipmentDefaults(
                purchasePrice: 65000,
                salvagePercentage: 40,
                expectedLifeHours: 8000,
                fuelBurnGPH: 2.5,
                maintenanceFactor: 50,
                insuranceRate: 2.5,
                annualHours: 2200
            )
        case .trailer:
            return EquipmentDefaults(
                purchasePrice: 15000,
                salvagePercentage: 30,
                expectedLifeHours: 10000,
                fuelBurnGPH: 0,
                maintenanceFactor: 30,
                insuranceRate: 2,
                annualHours: 2000
            )
        case .crane:
            return EquipmentDefaults(
                purchasePrice: 350000,
                salvagePercentage: 30,
                expectedLifeHours: 12000,
                fuelBurnGPH: 8.0,
                maintenanceFactor: 70,
                insuranceRate: 5,
                annualHours: 1500
            )
        case .miniExcavator:
            return EquipmentDefaults(
                purchasePrice: 70000,
                salvagePercentage: 25,
                expectedLifeHours: 8000,
                fuelBurnGPH: 3.0,
                maintenanceFactor: 75,
                insuranceRate: 3,
                annualHours: 1700
            )
        case .chainsaw:
            return EquipmentDefaults(
                purchasePrice: 1000,
                salvagePercentage: 10,
                expectedLifeHours: 2400,
                fuelBurnGPH: 0.3,
                maintenanceFactor: 100,
                insuranceRate: 0,
                annualHours: 1200
            )
        case .climbingGear:
            return EquipmentDefaults(
                purchasePrice: 1500,
                salvagePercentage: 10,
                expectedLifeHours: 5000,
                fuelBurnGPH: 0,
                maintenanceFactor: 20,
                insuranceRate: 0,
                annualHours: 1800
            )
        case .riggingEquipment:
            return EquipmentDefaults(
                purchasePrice: 1000,
                salvagePercentage: 10,
                expectedLifeHours: 5000,
                fuelBurnGPH: 0,
                maintenanceFactor: 20,
                insuranceRate: 0,
                annualHours: 1800
            )
        case .handTools:
            return EquipmentDefaults(
                purchasePrice: 400,
                salvagePercentage: 10,
                expectedLifeHours: 2400,
                fuelBurnGPH: 0,
                maintenanceFactor: 50,
                insuranceRate: 0,
                annualHours: 2000
            )
        case .safetyGear:
            return EquipmentDefaults(
                purchasePrice: 300,
                salvagePercentage: 0,
                expectedLifeHours: 2000,
                fuelBurnGPH: 0,
                maintenanceFactor: 0,
                insuranceRate: 0,
                annualHours: 2000
            )
        }
    }
}

struct EquipmentDefaults {
    let purchasePrice: Double
    let salvagePercentage: Double
    let expectedLifeHours: Double
    let fuelBurnGPH: Double
    let maintenanceFactor: Double
    let insuranceRate: Double
    let annualHours: Double
}

struct Equipment: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: EquipmentCategory
    var manufacturer: String
    var model: String
    var year: Int
    var serialNumber: String

    // Purchase Information
    var purchasePrice: Double
    var salvageValue: Double
    var expectedLifeHours: Double
    var annualHours: Double

    // Operating Costs
    var fuelBurnGPH: Double  // Gallons per hour
    var fuelPricePerGallon: Double
    var maintenanceFactor: Double // Percentage of depreciation
    var insuranceRate: Double // Annual percentage of purchase price

    // Calculated hourly cost
    var hourlyRate: Double {
        let depreciation = (purchasePrice - salvageValue) / expectedLifeHours
        let interest = ((purchasePrice + salvageValue) / 2 * 0.06) / annualHours
        let insurance = (purchasePrice * (insuranceRate / 100)) / annualHours
        let fuel = fuelBurnGPH * fuelPricePerGallon
        let maintenance = depreciation * (maintenanceFactor / 100)
        let wearParts = depreciation * 0.20

        return depreciation + interest + insurance + fuel + maintenance + wearParts
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: EquipmentCategory,
        manufacturer: String = "",
        model: String = "",
        year: Int = Calendar.current.component(.year, from: Date()),
        serialNumber: String = "",
        purchasePrice: Double,
        salvageValue: Double? = nil,
        expectedLifeHours: Double,
        annualHours: Double,
        fuelBurnGPH: Double,
        fuelPricePerGallon: Double = 4.25,
        maintenanceFactor: Double,
        insuranceRate: Double
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.manufacturer = manufacturer
        self.model = model
        self.year = year
        self.serialNumber = serialNumber
        self.purchasePrice = purchasePrice
        self.salvageValue = salvageValue ?? (purchasePrice * 0.25)
        self.expectedLifeHours = expectedLifeHours
        self.annualHours = annualHours
        self.fuelBurnGPH = fuelBurnGPH
        self.fuelPricePerGallon = fuelPricePerGallon
        self.maintenanceFactor = maintenanceFactor
        self.insuranceRate = insuranceRate
    }

    static func createWithDefaults(name: String, category: EquipmentCategory) -> Equipment {
        let defaults = category.defaultValues
        return Equipment(
            name: name,
            category: category,
            purchasePrice: defaults.purchasePrice,
            salvageValue: defaults.purchasePrice * (defaults.salvagePercentage / 100),
            expectedLifeHours: defaults.expectedLifeHours,
            annualHours: defaults.annualHours,
            fuelBurnGPH: defaults.fuelBurnGPH,
            maintenanceFactor: defaults.maintenanceFactor,
            insuranceRate: defaults.insuranceRate
        )
    }
}

// MARK: - Employee Models

enum EmployeePosition: String, CaseIterable, Codable, Identifiable {
    case groundCrewEntry = "Ground Crew (Entry)"
    case groundCrewExperienced = "Ground Crew (Experienced)"
    case climberApprentice = "Climber (Apprentice)"
    case climberExperienced = "Climber (Experienced)"
    case crewLeader = "Crew Leader"
    case certifiedArborist = "Certified Arborist"
    case equipmentOperator = "Equipment Operator"
    case foreman = "Foreman"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .groundCrewEntry, .groundCrewExperienced:
            return "person.fill"
        case .climberApprentice, .climberExperienced:
            return "figure.climbing"
        case .crewLeader, .foreman:
            return "person.badge.shield.checkmark"
        case .certifiedArborist:
            return "leaf.fill"
        case .equipmentOperator:
            return "gearshape.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .groundCrewEntry: return .gray
        case .groundCrewExperienced: return .blue
        case .climberApprentice: return .orange
        case .climberExperienced: return .red
        case .crewLeader: return .purple
        case .certifiedArborist: return .green
        case .equipmentOperator: return .brown
        case .foreman: return .indigo
        }
    }

    var defaultBurdenMultiplier: Double {
        switch self {
        case .groundCrewEntry: return 1.6
        case .groundCrewExperienced: return 1.65
        case .climberApprentice: return 1.7
        case .climberExperienced: return 1.75
        case .crewLeader: return 1.8
        case .certifiedArborist: return 1.9
        case .equipmentOperator: return 1.85
        case .foreman: return 2.0
        }
    }

    var typicalWageRange: ClosedRange<Double> {
        switch self {
        case .groundCrewEntry: return 15...20
        case .groundCrewExperienced: return 18...25
        case .climberApprentice: return 22...28
        case .climberExperienced: return 25...35
        case .crewLeader: return 30...40
        case .certifiedArborist: return 35...45
        case .equipmentOperator: return 28...38
        case .foreman: return 40...50
        }
    }
}

struct Employee: Identifiable, Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var position: EmployeePosition
    var baseHourlyRate: Double
    var burdenMultiplier: Double

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var trueHourlyCost: Double {
        baseHourlyRate * burdenMultiplier
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        position: EmployeePosition,
        baseHourlyRate: Double,
        burdenMultiplier: Double? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.position = position
        self.baseHourlyRate = baseHourlyRate
        self.burdenMultiplier = burdenMultiplier ?? position.defaultBurdenMultiplier
    }
}

// MARK: - Loadout Models

struct LoadoutEquipment: Codable, Identifiable {
    let id: UUID
    let equipmentId: UUID
    var utilizationPercentage: Double // 0-100

    init(id: UUID = UUID(), equipmentId: UUID, utilizationPercentage: Double = 100) {
        self.id = id
        self.equipmentId = equipmentId
        self.utilizationPercentage = utilizationPercentage
    }
}

struct LoadoutEmployee: Codable, Identifiable {
    let id: UUID
    let employeeId: UUID
    var role: String

    init(id: UUID = UUID(), employeeId: UUID, role: String = "") {
        self.id = id
        self.employeeId = employeeId
        self.role = role
    }
}

struct Loadout: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var equipment: [LoadoutEquipment]
    var employees: [LoadoutEmployee]

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        equipment: [LoadoutEquipment] = [],
        employees: [LoadoutEmployee] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.equipment = equipment
        self.employees = employees
    }

    func calculateHourlyCost(equipmentList: [Equipment], employeeList: [Employee]) -> LoadoutCostBreakdown {
        var equipmentCost = 0.0
        var employeeCost = 0.0

        for loadoutEquipment in equipment {
            if let equipment = equipmentList.first(where: { $0.id == loadoutEquipment.equipmentId }) {
                equipmentCost += equipment.hourlyRate * (loadoutEquipment.utilizationPercentage / 100)
            }
        }

        for loadoutEmployee in employees {
            if let employee = employeeList.first(where: { $0.id == loadoutEmployee.employeeId }) {
                employeeCost += employee.trueHourlyCost
            }
        }

        return LoadoutCostBreakdown(
            equipmentCost: equipmentCost,
            employeeCost: employeeCost,
            totalCost: equipmentCost + employeeCost
        )
    }
}

struct LoadoutCostBreakdown {
    let equipmentCost: Double
    let employeeCost: Double
    let totalCost: Double

    var withMarkup: Double {
        totalCost * 3.0 // Default 3x markup
    }
}

// MARK: - Template Loadouts

extension Loadout {
    static let treeRemovalStandard = Loadout(
        name: "Tree Removal - Standard",
        description: "Standard tree removal crew with bucket truck and chipper",
        equipment: [],
        employees: []
    )

    static let stumpGrindingBasic = Loadout(
        name: "Stump Grinding",
        description: "Basic stump grinding with operator",
        equipment: [],
        employees: []
    )

    static let forestryMulching = Loadout(
        name: "Forestry Mulching",
        description: "Land clearing with forestry mulcher",
        equipment: [],
        employees: []
    )

    static let emergencyResponse = Loadout(
        name: "Emergency Response",
        description: "24/7 emergency tree service crew",
        equipment: [],
        employees: []
    )
}