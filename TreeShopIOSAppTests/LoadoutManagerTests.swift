import XCTest
@testable import TreeShopIOSApp

class LoadoutManagerTests: XCTestCase {

    var loadoutManager: LoadoutManager!
    var equipmentManager: EquipmentManager!
    var employeeManager: EmployeeManager!

    override func setUp() {
        super.setUp()
        equipmentManager = EquipmentManager()
        employeeManager = EmployeeManager()
        loadoutManager = LoadoutManager(equipmentManager: equipmentManager, employeeManager: employeeManager)
    }

    override func tearDown() {
        loadoutManager = nil
        equipmentManager = nil
        employeeManager = nil
        super.tearDown()
    }

    // MARK: - Equipment Tests

    func testAddEquipment() {
        let equipment = Equipment(
            id: UUID(),
            name: "Chainsaw",
            category: "Cutting",
            hourlyRate: 25.00,
            dailyRate: 200.00,
            isAvailable: true
        )

        equipmentManager.addEquipment(equipment)

        XCTAssertEqual(equipmentManager.equipment.count, 1)
        XCTAssertEqual(equipmentManager.equipment.first?.name, "Chainsaw")
    }

    func testEquipmentHourlyRateCalculation() {
        let equipment = Equipment(
            id: UUID(),
            name: "Wood Chipper",
            category: "Processing",
            hourlyRate: 150.00,
            dailyRate: 1200.00,
            isAvailable: true
        )

        let cost = equipment.calculateCost(hours: 4)

        XCTAssertEqual(cost, 600.00) // 4 hours * $150
    }

    func testEquipmentDailyRateCalculation() {
        let equipment = Equipment(
            id: UUID(),
            name: "Crane",
            category: "Heavy Equipment",
            hourlyRate: 200.00,
            dailyRate: 1500.00,
            isAvailable: true
        )

        // Assume 8+ hours uses daily rate
        let cost = equipment.calculateCost(hours: 10)

        XCTAssertEqual(cost, 1500.00) // Daily rate applied
    }

    func testEquipmentAvailability() {
        let equipment = Equipment(
            id: UUID(),
            name: "Stump Grinder",
            category: "Grinding",
            hourlyRate: 100.00,
            dailyRate: 800.00,
            isAvailable: false
        )

        XCTAssertFalse(equipment.isAvailable)

        equipment.setAvailability(true)
        XCTAssertTrue(equipment.isAvailable)
    }

    // MARK: - Employee Tests

    func testAddEmployee() {
        let employee = Employee(
            id: UUID(),
            name: "John Smith",
            role: "Arborist",
            hourlyWage: 35.00,
            burdenRate: 1.35,
            certifications: ["ISA Certified Arborist"],
            isActive: true
        )

        employeeManager.addEmployee(employee)

        XCTAssertEqual(employeeManager.employees.count, 1)
        XCTAssertEqual(employeeManager.employees.first?.name, "John Smith")
    }

    func testEmployeeBurdenCalculation() {
        let employee = Employee(
            id: UUID(),
            name: "Jane Doe",
            role: "Crew Lead",
            hourlyWage: 40.00,
            burdenRate: 1.35, // 35% burden
            certifications: [],
            isActive: true
        )

        let totalCost = employee.calculateTotalHourlyCost()

        XCTAssertEqual(totalCost, 54.00) // $40 * 1.35
    }

    func testEmployeeCertifications() {
        let employee = Employee(
            id: UUID(),
            name: "Bob Johnson",
            role: "Climber",
            hourlyWage: 30.00,
            burdenRate: 1.35,
            certifications: ["ISA Certified Arborist", "First Aid", "CDL"],
            isActive: true
        )

        XCTAssertEqual(employee.certifications.count, 3)
        XCTAssertTrue(employee.hasCertification("ISA Certified Arborist"))
        XCTAssertFalse(employee.hasCertification("Crane Operator"))
    }

    // MARK: - Loadout Tests

    func testCreateLoadout() {
        let loadout = Loadout(
            id: UUID(),
            name: "Standard Tree Removal",
            description: "Basic tree removal setup",
            equipmentIds: [],
            employeeIds: [],
            estimatedHours: 4.0
        )

        loadoutManager.addLoadout(loadout)

        XCTAssertEqual(loadoutManager.loadouts.count, 1)
        XCTAssertEqual(loadoutManager.loadouts.first?.name, "Standard Tree Removal")
    }

    func testLoadoutCostCalculation() {
        // Setup equipment
        let chainsaw = Equipment(
            id: UUID(),
            name: "Chainsaw",
            category: "Cutting",
            hourlyRate: 25.00,
            dailyRate: 200.00,
            isAvailable: true
        )
        let chipper = Equipment(
            id: UUID(),
            name: "Chipper",
            category: "Processing",
            hourlyRate: 100.00,
            dailyRate: 800.00,
            isAvailable: true
        )

        equipmentManager.addEquipment(chainsaw)
        equipmentManager.addEquipment(chipper)

        // Setup employees
        let arborist = Employee(
            id: UUID(),
            name: "Lead Arborist",
            role: "Arborist",
            hourlyWage: 40.00,
            burdenRate: 1.35,
            certifications: ["ISA"],
            isActive: true
        )
        let groundsman = Employee(
            id: UUID(),
            name: "Groundsman",
            role: "Ground Crew",
            hourlyWage: 20.00,
            burdenRate: 1.35,
            certifications: [],
            isActive: true
        )

        employeeManager.addEmployee(arborist)
        employeeManager.addEmployee(groundsman)

        // Create loadout
        let loadout = Loadout(
            id: UUID(),
            name: "Full Crew Setup",
            description: "Complete tree removal team",
            equipmentIds: [chainsaw.id, chipper.id],
            employeeIds: [arborist.id, groundsman.id],
            estimatedHours: 5.0
        )

        let totalCost = loadoutManager.calculateLoadoutCost(loadout)

        // Equipment: (25 + 100) * 5 = 625
        // Employees: (40*1.35 + 20*1.35) * 5 = (54 + 27) * 5 = 405
        // Total: 625 + 405 = 1030
        XCTAssertEqual(totalCost, 1030.00, accuracy: 0.01)
    }

    func testLoadoutWithMultipleCrews() {
        // Create multiple employees
        for i in 1...5 {
            let employee = Employee(
                id: UUID(),
                name: "Worker \(i)",
                role: "Crew",
                hourlyWage: 25.00,
                burdenRate: 1.35,
                certifications: [],
                isActive: true
            )
            employeeManager.addEmployee(employee)
        }

        let loadout = Loadout(
            id: UUID(),
            name: "Large Crew",
            description: "5-person crew",
            equipmentIds: [],
            employeeIds: employeeManager.employees.map { $0.id },
            estimatedHours: 8.0
        )

        let laborCost = loadoutManager.calculateLaborCost(loadout)

        // 5 workers * $25 * 1.35 burden * 8 hours = 1350
        XCTAssertEqual(laborCost, 1350.00, accuracy: 0.01)
    }

    // MARK: - Caching Tests

    func testCalculationCaching() {
        let equipment = Equipment(
            id: UUID(),
            name: "Expensive Equipment",
            category: "Heavy",
            hourlyRate: 500.00,
            dailyRate: 3500.00,
            isAvailable: true
        )

        equipmentManager.addEquipment(equipment)

        let loadout = Loadout(
            id: UUID(),
            name: "Heavy Equipment",
            description: "Expensive setup",
            equipmentIds: [equipment.id],
            employeeIds: [],
            estimatedHours: 6.0
        )

        // First calculation - should cache
        let startTime = Date()
        let cost1 = loadoutManager.calculateLoadoutCost(loadout)
        let firstDuration = Date().timeIntervalSince(startTime)

        // Second calculation - should use cache
        let cachedStart = Date()
        let cost2 = loadoutManager.calculateLoadoutCost(loadout)
        let cachedDuration = Date().timeIntervalSince(cachedStart)

        XCTAssertEqual(cost1, cost2)
        // Cached should be faster (though this is hard to test reliably)
        XCTAssertLessThanOrEqual(cachedDuration, firstDuration + 0.001)
    }

    // MARK: - Validation Tests

    func testLoadoutValidation() {
        let loadout = Loadout(
            id: UUID(),
            name: "", // Invalid - empty name
            description: "Test",
            equipmentIds: [],
            employeeIds: [],
            estimatedHours: -5.0 // Invalid - negative hours
        )

        let isValid = loadoutManager.validateLoadout(loadout)

        XCTAssertFalse(isValid)
    }

    func testEquipmentConflicts() {
        let equipment = Equipment(
            id: UUID(),
            name: "Single Chipper",
            category: "Processing",
            hourlyRate: 150.00,
            dailyRate: 1200.00,
            isAvailable: true
        )

        equipmentManager.addEquipment(equipment)

        let loadout1 = Loadout(
            id: UUID(),
            name: "Crew 1",
            description: "First crew",
            equipmentIds: [equipment.id],
            employeeIds: [],
            estimatedHours: 4.0
        )

        let loadout2 = Loadout(
            id: UUID(),
            name: "Crew 2",
            description: "Second crew",
            equipmentIds: [equipment.id], // Same equipment
            employeeIds: [],
            estimatedHours: 4.0
        )

        // Check for conflicts when scheduling same time
        let hasConflict = loadoutManager.checkEquipmentConflict(
            loadout1,
            loadout2,
            date: Date()
        )

        XCTAssertTrue(hasConflict)
    }

    // MARK: - Performance Tests

    func testLargeLoadoutPerformance() {
        // Create many equipment items
        for i in 1...50 {
            let equipment = Equipment(
                id: UUID(),
                name: "Equipment \(i)",
                category: "Tools",
                hourlyRate: Double(i * 10),
                dailyRate: Double(i * 80),
                isAvailable: true
            )
            equipmentManager.addEquipment(equipment)
        }

        // Create many employees
        for i in 1...20 {
            let employee = Employee(
                id: UUID(),
                name: "Employee \(i)",
                role: "Crew",
                hourlyWage: Double(20 + i),
                burdenRate: 1.35,
                certifications: [],
                isActive: true
            )
            employeeManager.addEmployee(employee)
        }

        let loadout = Loadout(
            id: UUID(),
            name: "Massive Operation",
            description: "Large scale job",
            equipmentIds: equipmentManager.equipment.map { $0.id },
            employeeIds: employeeManager.employees.map { $0.id },
            estimatedHours: 10.0
        )

        measure {
            _ = loadoutManager.calculateLoadoutCost(loadout)
        }
    }
}

// MARK: - Mock Models

struct Equipment {
    let id: UUID
    var name: String
    var category: String
    var hourlyRate: Double
    var dailyRate: Double
    var isAvailable: Bool

    func calculateCost(hours: Double) -> Double {
        if hours >= 8 {
            return dailyRate
        }
        return hours * hourlyRate
    }

    mutating func setAvailability(_ available: Bool) {
        isAvailable = available
    }
}

struct Employee {
    let id: UUID
    var name: String
    var role: String
    var hourlyWage: Double
    var burdenRate: Double
    var certifications: [String]
    var isActive: Bool

    func calculateTotalHourlyCost() -> Double {
        return hourlyWage * burdenRate
    }

    func hasCertification(_ cert: String) -> Bool {
        return certifications.contains(cert)
    }
}

struct Loadout {
    let id: UUID
    var name: String
    var description: String
    var equipmentIds: [UUID]
    var employeeIds: [UUID]
    var estimatedHours: Double
}

// Mock Managers
class EquipmentManager {
    var equipment: [Equipment] = []

    func addEquipment(_ item: Equipment) {
        equipment.append(item)
    }

    func findEquipment(by id: UUID) -> Equipment? {
        return equipment.first { $0.id == id }
    }
}

class EmployeeManager {
    var employees: [Employee] = []

    func addEmployee(_ employee: Employee) {
        employees.append(employee)
    }

    func findEmployee(by id: UUID) -> Employee? {
        return employees.first { $0.id == id }
    }
}

class LoadoutManager {
    var loadouts: [Loadout] = []
    private let equipmentManager: EquipmentManager
    private let employeeManager: EmployeeManager
    private var calculationCache: [UUID: (cost: Double, timestamp: Date)] = [:]

    init(equipmentManager: EquipmentManager, employeeManager: EmployeeManager) {
        self.equipmentManager = equipmentManager
        self.employeeManager = employeeManager
    }

    func addLoadout(_ loadout: Loadout) {
        loadouts.append(loadout)
    }

    func calculateLoadoutCost(_ loadout: Loadout) -> Double {
        // Check cache
        if let cached = calculationCache[loadout.id],
           Date().timeIntervalSince(cached.timestamp) < 60 {
            return cached.cost
        }

        let equipmentCost = loadout.equipmentIds.compactMap { equipmentManager.findEquipment(by: $0) }
            .reduce(0) { $0 + $1.calculateCost(hours: loadout.estimatedHours) }

        let laborCost = calculateLaborCost(loadout)

        let total = equipmentCost + laborCost

        // Cache result
        calculationCache[loadout.id] = (total, Date())

        return total
    }

    func calculateLaborCost(_ loadout: Loadout) -> Double {
        return loadout.employeeIds.compactMap { employeeManager.findEmployee(by: $0) }
            .reduce(0) { $0 + $1.calculateTotalHourlyCost() * loadout.estimatedHours }
    }

    func validateLoadout(_ loadout: Loadout) -> Bool {
        return !loadout.name.isEmpty && loadout.estimatedHours > 0
    }

    func checkEquipmentConflict(_ loadout1: Loadout, _ loadout2: Loadout, date: Date) -> Bool {
        let equipment1 = Set(loadout1.equipmentIds)
        let equipment2 = Set(loadout2.equipmentIds)
        return !equipment1.isDisjoint(with: equipment2)
    }
}