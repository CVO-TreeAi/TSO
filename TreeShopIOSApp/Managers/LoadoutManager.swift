import Foundation
import SwiftUI

// MARK: - Equipment Manager

class EquipmentManager: ObservableObject {
    @Published var equipment: [Equipment] = []
    private let saveKey = "TSO_Equipment"

    init() {
        loadEquipment()
        if equipment.isEmpty {
            loadSampleEquipment()
        }
    }

    func addEquipment(_ newEquipment: Equipment) {
        equipment.append(newEquipment)
        saveEquipment()
    }

    func updateEquipment(_ updatedEquipment: Equipment) {
        if let index = equipment.firstIndex(where: { $0.id == updatedEquipment.id }) {
            equipment[index] = updatedEquipment
            saveEquipment()
        }
    }

    func deleteEquipment(_ equipmentToDelete: Equipment) {
        equipment.removeAll { $0.id == equipmentToDelete.id }
        saveEquipment()
    }

    func getEquipment(by id: UUID) -> Equipment? {
        equipment.first { $0.id == id }
    }

    private func saveEquipment() {
        if let encoded = try? JSONEncoder().encode(equipment) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadEquipment() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Equipment].self, from: data) {
            equipment = decoded
        }
    }

    private func loadSampleEquipment() {
        equipment = [
            Equipment(
                name: "Altec Bucket Truck #1",
                category: .bucketTruck,
                manufacturer: "Altec",
                model: "LRV-60",
                year: 2021,
                purchasePrice: 165000,
                salvageValue: 49500,
                expectedLifeHours: 10000,
                annualHours: 2000,
                fuelBurnGPH: 6.5,
                maintenanceFactor: 60,
                insuranceRate: 3
            ),
            Equipment(
                name: "Bandit Chipper #1",
                category: .chipper,
                manufacturer: "Bandit",
                model: "150XP",
                year: 2022,
                purchasePrice: 50000,
                salvageValue: 12500,
                expectedLifeHours: 5000,
                annualHours: 1800,
                fuelBurnGPH: 2.5,
                maintenanceFactor: 90,
                insuranceRate: 3
            ),
            Equipment(
                name: "Rayco Stump Grinder",
                category: .stumpGrinder,
                manufacturer: "Rayco",
                model: "RG80",
                year: 2020,
                purchasePrice: 45000,
                salvageValue: 11250,
                expectedLifeHours: 5000,
                annualHours: 1600,
                fuelBurnGPH: 2.8,
                maintenanceFactor: 90,
                insuranceRate: 3
            ),
            Equipment(
                name: "F-350 Dump Truck",
                category: .dumpTruck,
                manufacturer: "Ford",
                model: "F-350",
                year: 2022,
                purchasePrice: 85000,
                salvageValue: 29750,
                expectedLifeHours: 8000,
                annualHours: 2000,
                fuelBurnGPH: 4.0,
                maintenanceFactor: 50,
                insuranceRate: 3
            ),
            Equipment(
                name: "Service Truck",
                category: .pickupTruck,
                manufacturer: "Chevrolet",
                model: "Silverado 2500",
                year: 2023,
                purchasePrice: 65000,
                salvageValue: 26000,
                expectedLifeHours: 8000,
                annualHours: 2200,
                fuelBurnGPH: 2.5,
                maintenanceFactor: 50,
                insuranceRate: 2.5
            ),
            Equipment.createWithDefaults(name: "Equipment Trailer", category: .trailer),
            Equipment.createWithDefaults(name: "Stihl MS 661", category: .chainsaw),
            Equipment.createWithDefaults(name: "Climbing Kit", category: .climbingGear),
            Equipment.createWithDefaults(name: "Rigging Set", category: .riggingEquipment)
        ]
        saveEquipment()
    }
}

// MARK: - Employee Manager

class EmployeeManager: ObservableObject {
    @Published var employees: [Employee] = []
    private let saveKey = "TSO_Employees"

    init() {
        loadEmployees()
        if employees.isEmpty {
            loadSampleEmployees()
        }
    }

    func addEmployee(_ newEmployee: Employee) {
        employees.append(newEmployee)
        saveEmployees()
    }

    func updateEmployee(_ updatedEmployee: Employee) {
        if let index = employees.firstIndex(where: { $0.id == updatedEmployee.id }) {
            employees[index] = updatedEmployee
            saveEmployees()
        }
    }

    func deleteEmployee(_ employeeToDelete: Employee) {
        employees.removeAll { $0.id == employeeToDelete.id }
        saveEmployees()
    }

    func getEmployee(by id: UUID) -> Employee? {
        employees.first { $0.id == id }
    }

    private func saveEmployees() {
        if let encoded = try? JSONEncoder().encode(employees) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadEmployees() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Employee].self, from: data) {
            employees = decoded
        }
    }

    private func loadSampleEmployees() {
        employees = [
            Employee(
                firstName: "Mike",
                lastName: "Johnson",
                position: .crewLeader,
                baseHourlyRate: 35.00
            ),
            Employee(
                firstName: "Tom",
                lastName: "Anderson",
                position: .certifiedArborist,
                baseHourlyRate: 40.00
            ),
            Employee(
                firstName: "Jake",
                lastName: "Williams",
                position: .climberExperienced,
                baseHourlyRate: 28.00
            ),
            Employee(
                firstName: "Carlos",
                lastName: "Rodriguez",
                position: .climberExperienced,
                baseHourlyRate: 26.00
            ),
            Employee(
                firstName: "David",
                lastName: "Miller",
                position: .groundCrewExperienced,
                baseHourlyRate: 22.00
            ),
            Employee(
                firstName: "Ryan",
                lastName: "Thompson",
                position: .groundCrewExperienced,
                baseHourlyRate: 20.00
            ),
            Employee(
                firstName: "Alex",
                lastName: "Martinez",
                position: .groundCrewEntry,
                baseHourlyRate: 18.00
            ),
            Employee(
                firstName: "Steve",
                lastName: "Cooper",
                position: .equipmentOperator,
                baseHourlyRate: 32.00
            )
        ]
        saveEmployees()
    }

    func calculateTotalBurdenCost(for employee: Employee) -> BurdenCostBreakdown {
        let baseCost = employee.baseHourlyRate
        let burdenAmount = baseCost * (employee.burdenMultiplier - 1)

        // Estimate burden components
        let taxBurden = baseCost * 0.30
        let benefitsBurden = baseCost * 0.25
        let overheadBurden = baseCost * (employee.burdenMultiplier - 1.55)

        return BurdenCostBreakdown(
            baseWage: baseCost,
            taxBurden: taxBurden,
            benefitsBurden: benefitsBurden,
            overheadBurden: overheadBurden,
            totalBurden: burdenAmount,
            trueHourlyCost: employee.trueHourlyCost
        )
    }
}

struct BurdenCostBreakdown {
    let baseWage: Double
    let taxBurden: Double
    let benefitsBurden: Double
    let overheadBurden: Double
    let totalBurden: Double
    let trueHourlyCost: Double
}

// MARK: - Loadout Manager

class LoadoutManager: ObservableObject {
    @Published var loadouts: [Loadout] = []
    @Published var equipmentManager: EquipmentManager
    @Published var employeeManager: EmployeeManager

    private let saveKey = "TSO_Loadouts"

    init(equipmentManager: EquipmentManager, employeeManager: EmployeeManager) {
        self.equipmentManager = equipmentManager
        self.employeeManager = employeeManager
        loadLoadouts()
        if loadouts.isEmpty {
            createDefaultLoadouts()
        }
    }

    func addLoadout(_ newLoadout: Loadout) {
        loadouts.append(newLoadout)
        saveLoadouts()
    }

    func updateLoadout(_ updatedLoadout: Loadout) {
        if let index = loadouts.firstIndex(where: { $0.id == updatedLoadout.id }) {
            loadouts[index] = updatedLoadout
            saveLoadouts()
        }
    }

    func deleteLoadout(_ loadoutToDelete: Loadout) {
        loadouts.removeAll { $0.id == loadoutToDelete.id }
        saveLoadouts()
    }

    func calculateLoadoutCost(_ loadout: Loadout) -> LoadoutCostBreakdown {
        loadout.calculateHourlyCost(
            equipmentList: equipmentManager.equipment,
            employeeList: employeeManager.employees
        )
    }

    private func saveLoadouts() {
        if let encoded = try? JSONEncoder().encode(loadouts) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadLoadouts() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Loadout].self, from: data) {
            loadouts = decoded
        }
    }

    private func createDefaultLoadouts() {
        // Tree Removal Standard Loadout
        let bucketTruck = equipmentManager.equipment.first(where: { $0.category == .bucketTruck })
        let chipper = equipmentManager.equipment.first(where: { $0.category == .chipper })
        let dumpTruck = equipmentManager.equipment.first(where: { $0.category == .dumpTruck })
        let crewLeader = employeeManager.employees.first(where: { $0.position == .crewLeader })
        let climber = employeeManager.employees.first(where: { $0.position == .climberExperienced })
        let groundCrew1 = employeeManager.employees.first(where: { $0.position == .groundCrewExperienced })
        let groundCrew2 = employeeManager.employees.last(where: { $0.position == .groundCrewExperienced })

        if let bucketTruck = bucketTruck,
           let chipper = chipper,
           let dumpTruck = dumpTruck,
           let crewLeader = crewLeader,
           let climber = climber,
           let groundCrew1 = groundCrew1,
           let groundCrew2 = groundCrew2 {

            let treeRemoval = Loadout(
                name: "Tree Removal - Standard",
                description: "Standard tree removal crew with bucket truck and chipper",
                equipment: [
                    LoadoutEquipment(equipmentId: bucketTruck.id, utilizationPercentage: 100),
                    LoadoutEquipment(equipmentId: chipper.id, utilizationPercentage: 80),
                    LoadoutEquipment(equipmentId: dumpTruck.id, utilizationPercentage: 100)
                ],
                employees: [
                    LoadoutEmployee(employeeId: crewLeader.id, role: "Crew Leader"),
                    LoadoutEmployee(employeeId: climber.id, role: "Primary Climber"),
                    LoadoutEmployee(employeeId: groundCrew1.id, role: "Ground Support"),
                    LoadoutEmployee(employeeId: groundCrew2.id, role: "Ground Support")
                ]
            )
            loadouts.append(treeRemoval)
        }

        // Stump Grinding Loadout
        let stumpGrinder = equipmentManager.equipment.first(where: { $0.category == .stumpGrinder })
        let pickupTruck = equipmentManager.equipment.first(where: { $0.category == .pickupTruck })
        let equipmentOperator = employeeManager.employees.first(where: { $0.position == .equipmentOperator })
        let helper = employeeManager.employees.first(where: { $0.position == .groundCrewEntry })

        if let stumpGrinder = stumpGrinder,
           let pickupTruck = pickupTruck,
           let equipmentOperator = equipmentOperator,
           let helper = helper {

            let stumpGrinding = Loadout(
                name: "Stump Grinding",
                description: "Basic stump grinding with operator",
                equipment: [
                    LoadoutEquipment(equipmentId: stumpGrinder.id, utilizationPercentage: 100),
                    LoadoutEquipment(equipmentId: pickupTruck.id, utilizationPercentage: 100)
                ],
                employees: [
                    LoadoutEmployee(employeeId: equipmentOperator.id, role: "Equipment Operator"),
                    LoadoutEmployee(employeeId: helper.id, role: "Helper")
                ]
            )
            loadouts.append(stumpGrinding)
        }

        saveLoadouts()
    }
}