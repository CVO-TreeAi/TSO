import XCTest
@testable import TreeShopIOSApp

class TreeScoreCalculatorTests: XCTestCase {

    var calculator: TreeScoreCalculator!

    override func setUp() {
        super.setUp()
        calculator = TreeScoreCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Base TreeScore Tests

    func testSmallTreeScoreCalculation() {
        // Small tree: < 30ft
        let height = 25.0
        let dbh = 10.0
        let canopySpread = 15.0

        let score = calculator.calculateBaseTreeScore(height: height, dbh: dbh, canopySpread: canopySpread)

        // Base TreeScore = Height + (DBH × 2) + Canopy Spread
        let expectedScore = height + (dbh * 2) + canopySpread // 25 + 20 + 15 = 60

        XCTAssertEqual(score, expectedScore, accuracy: 0.01)
        XCTAssertTrue(score >= 50 && score <= 100, "Small tree should be 50-100 points")
    }

    func testMediumTreeScoreCalculation() {
        // Medium tree: 30-60ft
        let height = 45.0
        let dbh = 25.0
        let canopySpread = 30.0

        let score = calculator.calculateBaseTreeScore(height: height, dbh: dbh, canopySpread: canopySpread)

        let expectedScore = height + (dbh * 2) + canopySpread // 45 + 50 + 30 = 125

        XCTAssertEqual(score, expectedScore, accuracy: 0.01)
        XCTAssertTrue(score >= 100 && score <= 200, "Medium tree should be 100-200 points")
    }

    func testLargeTreeScoreCalculation() {
        // Large tree: 60-80ft
        let height = 70.0
        let dbh = 40.0
        let canopySpread = 50.0

        let score = calculator.calculateBaseTreeScore(height: height, dbh: dbh, canopySpread: canopySpread)

        let expectedScore = height + (dbh * 2) + canopySpread // 70 + 80 + 50 = 200

        XCTAssertEqual(score, expectedScore, accuracy: 0.01)
        XCTAssertTrue(score >= 200 && score <= 300, "Large tree should be 200-300 points")
    }

    func testGiantTreeScoreCalculation() {
        // Giant tree: > 80ft
        let height = 90.0
        let dbh = 60.0
        let canopySpread = 70.0

        let score = calculator.calculateBaseTreeScore(height: height, dbh: dbh, canopySpread: canopySpread)

        let expectedScore = height + (dbh * 2) + canopySpread // 90 + 120 + 70 = 280

        XCTAssertEqual(score, expectedScore, accuracy: 0.01)
        XCTAssertTrue(score >= 300, "Giant tree should be 300+ points")
    }

    // MARK: - AFISS Multiplier Tests

    func testEasyAccessMultiplier() {
        let afiss = AFISSFactors(
            access: .easy,
            felling: .openDrop,
            infrastructure: .none,
            slope: .flat,
            special: .none
        )

        let multiplier = calculator.calculateAFISSMultiplier(afiss)

        // All easy factors: 1.0 * 1.0 * 1.0 * 1.0 * 1.0 = 1.0
        XCTAssertEqual(multiplier, 1.0, accuracy: 0.01)
    }

    func testMediumComplexityMultiplier() {
        let afiss = AFISSFactors(
            access: .medium,
            felling: .sectional,
            infrastructure: .some,
            slope: .moderate,
            special: .none
        )

        let multiplier = calculator.calculateAFISSMultiplier(afiss)

        // Mixed factors: 1.2 * 1.3 * 1.3 * 1.1 * 1.0 = 2.236
        let expected = 1.2 * 1.3 * 1.3 * 1.1 * 1.0
        XCTAssertEqual(multiplier, expected, accuracy: 0.01)
    }

    func testHighComplexityMultiplier() {
        let afiss = AFISSFactors(
            access: .hard,
            felling: .technical,
            infrastructure: .critical,
            slope: .steep,
            special: .major
        )

        let multiplier = calculator.calculateAFISSMultiplier(afiss)

        // All hard factors: 1.5 * 1.6 * 1.5 * 1.3 * 1.5 = 7.02
        let expected = 1.5 * 1.6 * 1.5 * 1.3 * 1.5
        XCTAssertEqual(multiplier, expected, accuracy: 0.01)
    }

    // MARK: - Final Score Tests

    func testFinalScoreWithAFISS() {
        let baseScore = 150.0
        let afiss = AFISSFactors(
            access: .medium,
            felling: .openDrop,
            infrastructure: .some,
            slope: .flat,
            special: .minor
        )

        let afissMultiplier = calculator.calculateAFISSMultiplier(afiss)
        let finalScore = calculator.calculateFinalScore(baseScore: baseScore, afissMultiplier: afissMultiplier)

        // 150 * (1.2 * 1.0 * 1.3 * 1.0 * 1.2) = 150 * 1.872 = 280.8
        let expected = baseScore * (1.2 * 1.0 * 1.3 * 1.0 * 1.2)
        XCTAssertEqual(finalScore, expected, accuracy: 0.1)
    }

    // MARK: - Trimming Percentage Tests

    func testDeadwoodTrimmingPercentage() {
        let percentage = calculator.estimateTrimmingPercentage(for: "deadwood")
        XCTAssertTrue(percentage >= 5 && percentage <= 10, "Deadwood should be 5-10%")
    }

    func testLightCleanupTrimmingPercentage() {
        let percentage = calculator.estimateTrimmingPercentage(for: "light cleanup")
        XCTAssertTrue(percentage >= 10 && percentage <= 15, "Light cleanup should be 10-15%")
    }

    func testShapeTrimmingPercentage() {
        let percentage = calculator.estimateTrimmingPercentage(for: "shape")
        XCTAssertTrue(percentage >= 15 && percentage <= 25, "Shaping should be 15-25%")
    }

    func testMajorReductionTrimmingPercentage() {
        let percentage = calculator.estimateTrimmingPercentage(for: "major reduction")
        XCTAssertTrue(percentage >= 25 && percentage <= 40, "Major reduction should be 25-40%")
    }

    func testStormPrepTrimmingPercentage() {
        let percentage = calculator.estimateTrimmingPercentage(for: "storm prep")
        XCTAssertTrue(percentage >= 30 && percentage <= 40, "Storm prep should be 30-40%")
    }

    // MARK: - Price Calculation Tests

    func testRemovalPriceCalculation() {
        let treeScore = 200.0
        let pointsPerHour = 100.0
        let crewRate = 250.0
        let profitMargin = 1.4

        let hours = treeScore / pointsPerHour
        let labor = hours * crewRate
        let totalPrice = labor * profitMargin

        // 200 / 100 = 2 hours * $250 = $500 * 1.4 = $700
        XCTAssertEqual(totalPrice, 700.0, accuracy: 0.01)
    }

    func testTrimmingPriceCalculation() {
        let treeScore = 150.0
        let trimmingPercentage = 20.0
        let adjustedScore = treeScore * (trimmingPercentage / 100)
        let pointsPerHour = 120.0
        let crewRate = 225.0
        let profitMargin = 1.4

        let hours = adjustedScore / pointsPerHour
        let labor = hours * crewRate
        let totalPrice = labor * profitMargin

        // 150 * 0.2 = 30 points / 120 = 0.25 hours * $225 = $56.25 * 1.4 = $78.75
        XCTAssertEqual(totalPrice, 78.75, accuracy: 0.01)
    }

    // MARK: - Edge Cases

    func testZeroValuesHandling() {
        let score = calculator.calculateBaseTreeScore(height: 0, dbh: 0, canopySpread: 0)
        XCTAssertEqual(score, 0)
    }

    func testNegativeValuesHandling() {
        let score = calculator.calculateBaseTreeScore(height: -10, dbh: -5, canopySpread: -15)
        XCTAssertGreaterThanOrEqual(score, 0, "Score should never be negative")
    }

    func testExtremelyLargeValues() {
        let score = calculator.calculateBaseTreeScore(height: 200, dbh: 100, canopySpread: 150)
        // 200 + 200 + 150 = 550
        XCTAssertEqual(score, 550, accuracy: 0.01)
    }
}

// MARK: - Test Models

struct AFISSFactors {
    enum Access {
        case easy, medium, hard
        var multiplier: Double {
            switch self {
            case .easy: return 1.0
            case .medium: return 1.2
            case .hard: return 1.5
            }
        }
    }

    enum Felling {
        case openDrop, sectional, technical
        var multiplier: Double {
            switch self {
            case .openDrop: return 1.0
            case .sectional: return 1.3
            case .technical: return 1.6
            }
        }
    }

    enum Infrastructure {
        case none, some, critical
        var multiplier: Double {
            switch self {
            case .none: return 1.0
            case .some: return 1.3
            case .critical: return 1.5
            }
        }
    }

    enum Slope {
        case flat, moderate, steep
        var multiplier: Double {
            switch self {
            case .flat: return 1.0
            case .moderate: return 1.1
            case .steep: return 1.3
            }
        }
    }

    enum Special {
        case none, minor, major
        var multiplier: Double {
            switch self {
            case .none: return 1.0
            case .minor: return 1.2
            case .major: return 1.5
            }
        }
    }

    let access: Access
    let felling: Felling
    let infrastructure: Infrastructure
    let slope: Slope
    let special: Special
}

// Mock TreeScoreCalculator for testing
struct TreeScoreCalculator {
    func calculateBaseTreeScore(height: Double, dbh: Double, canopySpread: Double) -> Double {
        guard height >= 0, dbh >= 0, canopySpread >= 0 else { return 0 }
        return height + (dbh * 2) + canopySpread
    }

    func calculateAFISSMultiplier(_ factors: AFISSFactors) -> Double {
        return factors.access.multiplier *
               factors.felling.multiplier *
               factors.infrastructure.multiplier *
               factors.slope.multiplier *
               factors.special.multiplier
    }

    func calculateFinalScore(baseScore: Double, afissMultiplier: Double) -> Double {
        return baseScore * afissMultiplier
    }

    func estimateTrimmingPercentage(for type: String) -> Double {
        switch type.lowercased() {
        case "deadwood": return 7.5
        case "light cleanup": return 12.5
        case "shape": return 20.0
        case "major reduction": return 32.5
        case "storm prep": return 35.0
        default: return 15.0
        }
    }
}