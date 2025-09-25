import Foundation
import SwiftUI
import Combine

// MARK: - Performance Optimized Managers

extension EquipmentManager {
    // Cache for expensive calculations
    private struct CachedCalculation {
        let value: Double
        let timestamp: Date
    }

    private static var calculationCache: [UUID: CachedCalculation] = [:]
    private static let cacheExpiration: TimeInterval = 60 // 1 minute

    func getCachedHourlyRate(for equipment: Equipment) -> Double {
        let cacheKey = equipment.id

        // Check if we have a valid cached value
        if let cached = Self.calculationCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < Self.cacheExpiration {
            return cached.value
        }

        // Calculate and cache
        let rate = equipment.hourlyRate
        Self.calculationCache[cacheKey] = CachedCalculation(value: rate, timestamp: Date())
        return rate
    }

    func clearCache() {
        Self.calculationCache.removeAll()
    }
}

extension EmployeeManager {
    // Use dictionary for O(1) lookups instead of O(n) array searches
    private var employeeDict: [UUID: Employee] {
        Dictionary(uniqueKeysWithValues: employees.map { ($0.id, $0) })
    }

    func getEmployeeFast(by id: UUID) -> Employee? {
        employeeDict[id]
    }
}

extension LoadoutManager {
    // Cache loadout calculations
    private static var loadoutCostCache: [UUID: LoadoutCostBreakdown] = [:]

    func getCachedLoadoutCost(_ loadout: Loadout) -> LoadoutCostBreakdown {
        if let cached = Self.loadoutCostCache[loadout.id] {
            return cached
        }

        let cost = calculateLoadoutCost(loadout)
        Self.loadoutCostCache[loadout.id] = cost
        return cost
    }

    func invalidateCostCache() {
        Self.loadoutCostCache.removeAll()
    }
}

// MARK: - Optimized View Components

struct LazyEmployeeCard: View {
    let employee: Employee
    @ObservedObject var employeeManager: EmployeeManager
    @State private var burdenBreakdown: BurdenCostBreakdown?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: employee.position.icon)
                    .font(.largeTitle)
                    .foregroundColor(employee.position.color)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(employee.fullName)
                        .font(.headline)
                    Text(employee.position.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(employee.trueHourlyCost, specifier: "%.2f")/hr")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("\(employee.burdenMultiplier, specifier: "%.2f")x burden")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            // Lazy load the cost breakdown
            if let breakdown = burdenBreakdown {
                VStack(spacing: 8) {
                    EmployeeCostBreakdownRow(label: "Base Wage", amount: breakdown.baseWage, isBase: true)
                    EmployeeCostBreakdownRow(label: "Tax & Benefits", amount: breakdown.totalBurden, isAddition: true)
                    Divider()
                    EmployeeCostBreakdownRow(label: "True Cost", amount: breakdown.trueHourlyCost, isTotal: true)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            // Only calculate when the view appears
            if burdenBreakdown == nil {
                burdenBreakdown = employeeManager.calculateTotalBurdenCost(for: employee)
            }
        }
    }
}

// MARK: - List Performance Optimizations

struct OptimizedEquipmentList: View {
    let equipment: [Equipment]
    let onTap: (Equipment) -> Void

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(equipment) { equipment in
                EquipmentCard(equipment: equipment)
                    .onTapGesture {
                        onTap(equipment)
                    }
                    .id(equipment.id) // Helps SwiftUI optimize redraws
            }
        }
    }
}

// MARK: - Memoized Calculations

struct MemoizedCalculations {
    private static var cache: [String: Any] = [:]

    static func memoize<T>(_ key: String, calculation: () -> T) -> T {
        if let cached = cache[key] as? T {
            return cached
        }
        let result = calculation()
        cache[key] = result
        return result
    }

    static func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Debounced Search

class DebouncedSearchModel: ObservableObject {
    @Published var searchText = ""
    @Published var debouncedSearchText = ""

    private var debounceTimer: Timer?

    init() {
        setupDebounce()
    }

    private func setupDebounce() {
        $searchText
            .sink { [weak self] text in
                self?.debounceTimer?.invalidate()
                self?.debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    self?.debouncedSearchText = text
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Batch Updates

extension EquipmentManager {
    func batchUpdate(_ updates: [(Equipment) -> Equipment]) {
        objectWillChange.send()

        for (index, item) in equipment.enumerated() {
            if index < updates.count {
                equipment[index] = updates[index](item)
            }
        }

        // Trigger save through public method
        if let first = equipment.first {
            updateEquipment(first)
        }
    }
}

// MARK: - Lazy Loading Views

struct LazyLoadingView<Content: View, Placeholder: View>: View {
    let content: () -> Content
    let placeholder: Placeholder
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                content()
            } else {
                placeholder
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                isLoaded = true
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Performance Monitoring

#if DEBUG
struct PerformanceMonitor {
    static func measure<T>(_ label: String, block: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let end = CFAbsoluteTimeGetCurrent()
        print("⏱ \(label): \((end - start) * 1000)ms")
        return result
    }
}
#endif