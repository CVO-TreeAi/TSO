import Foundation
import MapKit
import CoreLocation

// MARK: - Drawing Manager for Polygons and Points
class DrawingManager: ObservableObject {

    // MARK: - Drawing States
    enum DrawingMode {
        case none
        case polygon      // For work areas (mulching, clearing)
        case tree         // For individual tree markers
        case stump        // For stump markers
        case measuring    // For distance/area measurements
    }

    @Published var currentMode: DrawingMode = .none
    @Published var isDrawing = false

    // Polygon drawing
    @Published var currentPolygonPoints: [CLLocationCoordinate2D] = []
    @Published var workAreaPolygons: [WorkAreaPolygon] = []

    // Tree/Stump markers
    @Published var treeMarkers: [TreeMarker] = []
    @Published var stumpMarkers: [StumpMarker] = []

    // Measurements
    @Published var measurementPoints: [CLLocationCoordinate2D] = []
    @Published var currentMeasurement: MeasurementResult?

    // MARK: - Polygon Drawing Methods

    func startDrawingPolygon() {
        currentMode = .polygon
        isDrawing = true
        currentPolygonPoints.removeAll()
    }

    func addPolygonPoint(_ coordinate: CLLocationCoordinate2D) {
        guard currentMode == .polygon && isDrawing else { return }
        currentPolygonPoints.append(coordinate)
    }

    func finishPolygon(name: String, serviceType: ServiceType, notes: String? = nil) {
        guard currentPolygonPoints.count >= 3 else { return }

        let polygon = WorkAreaPolygon(
            points: currentPolygonPoints,
            name: name,
            serviceType: serviceType,
            notes: notes
        )

        workAreaPolygons.append(polygon)
        currentPolygonPoints.removeAll()
        isDrawing = false
        currentMode = .none
    }

    func cancelDrawing() {
        currentPolygonPoints.removeAll()
        measurementPoints.removeAll()
        isDrawing = false
        currentMode = .none
        currentMeasurement = nil
    }

    // MARK: - Tree/Stump Marking

    func addTreeMarker(at coordinate: CLLocationCoordinate2D, species: String? = nil, dbh: Double? = nil, height: Double? = nil) {
        let tree = TreeMarker(
            coordinate: coordinate,
            species: species,
            dbh: dbh,
            height: height
        )
        treeMarkers.append(tree)
    }

    func addStumpMarker(at coordinate: CLLocationCoordinate2D, diameter: Double? = nil) {
        let stump = StumpMarker(
            coordinate: coordinate,
            diameter: diameter
        )
        stumpMarkers.append(stump)
    }

    // MARK: - Measurement Tools

    func startMeasuring() {
        currentMode = .measuring
        isDrawing = true
        measurementPoints.removeAll()
        currentMeasurement = nil
    }

    func addMeasurementPoint(_ coordinate: CLLocationCoordinate2D) {
        guard currentMode == .measuring && isDrawing else { return }
        measurementPoints.append(coordinate)
        updateMeasurement()
    }

    private func updateMeasurement() {
        guard measurementPoints.count >= 2 else { return }

        if measurementPoints.count == 2 {
            // Distance measurement
            let distance = calculateDistance(from: measurementPoints[0], to: measurementPoints[1])
            currentMeasurement = MeasurementResult(
                type: .distance,
                value: distance,
                unit: "meters",
                displayValue: formatDistance(distance)
            )
        } else if measurementPoints.count >= 3 {
            // Area measurement
            let area = calculatePolygonArea(measurementPoints)
            let perimeter = calculatePolygonPerimeter(measurementPoints)
            currentMeasurement = MeasurementResult(
                type: .area,
                value: area,
                unit: "square meters",
                displayValue: formatArea(area),
                perimeter: perimeter
            )
        }
    }

    // MARK: - Calculation Helpers

    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    private func calculatePolygonArea(_ points: [CLLocationCoordinate2D]) -> Double {
        guard points.count >= 3 else { return 0 }

        var area = 0.0
        let earthRadius = 6371000.0 // Earth radius in meters

        // Convert to radians and calculate area using Shoelace formula
        let radiansPoints = points.map { coord in
            (lat: coord.latitude * .pi / 180, lon: coord.longitude * .pi / 180)
        }

        for i in 0..<radiansPoints.count {
            let j = (i + 1) % radiansPoints.count
            area += radiansPoints[i].lon * radiansPoints[j].lat
            area -= radiansPoints[j].lon * radiansPoints[i].lat
        }

        area = abs(area) * earthRadius * earthRadius / 2.0
        return area
    }

    private func calculatePolygonPerimeter(_ points: [CLLocationCoordinate2D]) -> Double {
        guard points.count >= 2 else { return 0 }

        var perimeter = 0.0
        for i in 0..<points.count {
            let j = (i + 1) % points.count
            perimeter += calculateDistance(from: points[i], to: points[j])
        }
        return perimeter
    }

    // MARK: - Formatting Helpers

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.1f m", meters)
        } else {
            return String(format: "%.2f km", meters / 1000)
        }
    }

    private func formatArea(_ squareMeters: Double) -> String {
        let squareFeet = squareMeters * 10.764
        let acres = squareMeters / 4047

        if acres > 0.5 {
            return String(format: "%.2f acres (%.0f sq ft)", acres, squareFeet)
        } else {
            return String(format: "%.0f sq ft (%.3f acres)", squareFeet, acres)
        }
    }

    // MARK: - Export for Line Items

    func exportPolygonToLineItem(_ polygon: WorkAreaPolygon) -> [String: Any] {
        let area = calculatePolygonArea(polygon.points)
        let perimeter = calculatePolygonPerimeter(polygon.points)

        return [
            "id": polygon.id.uuidString,
            "name": polygon.name,
            "serviceType": polygon.serviceType.rawValue,
            "area": area,
            "areaFormatted": formatArea(area),
            "perimeter": perimeter,
            "perimeterFormatted": formatDistance(perimeter),
            "coordinates": polygon.points.map { ["lat": $0.latitude, "lon": $0.longitude] },
            "createdAt": polygon.createdAt.timeIntervalSince1970,
            "notes": polygon.notes ?? ""
        ]
    }

    func calculatePricingForPolygon(_ polygon: WorkAreaPolygon) -> Double {
        let area = calculatePolygonArea(polygon.points)
        let acres = area / 4047

        // Pricing based on service type and area
        let pricePerAcre: Double
        switch polygon.serviceType {
        case .clearing:
            pricePerAcre = 3500
        case .thinning:
            pricePerAcre = 1600
        case .removal:
            pricePerAcre = 2200
        case .pruning:
            pricePerAcre = 1200
        case .emergency:
            pricePerAcre = 4500
        }

        return acres * pricePerAcre
    }
}

// MARK: - Data Models

struct WorkAreaPolygon: Identifiable {
    let id = UUID()
    let points: [CLLocationCoordinate2D]
    let name: String
    let serviceType: ServiceType
    let notes: String?
    let createdAt = Date()
    var lineItemId: UUID?  // Link to CDLineItem

    var polygon: MKPolygon {
        MKPolygon(coordinates: points, count: points.count)
    }
}

class TreeMarker: NSObject, Identifiable, MKAnnotation {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let species: String?
    let dbh: Double?  // Diameter at breast height
    let height: Double?
    let createdAt = Date()
    var treeScore: Double?
    var lineItemId: UUID?

    init(coordinate: CLLocationCoordinate2D, species: String? = nil, dbh: Double? = nil, height: Double? = nil) {
        self.coordinate = coordinate
        self.species = species
        self.dbh = dbh
        self.height = height
        super.init()
    }
}

class StumpMarker: NSObject, Identifiable, MKAnnotation {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let diameter: Double?
    let createdAt = Date()
    var lineItemId: UUID?

    init(coordinate: CLLocationCoordinate2D, diameter: Double? = nil) {
        self.coordinate = coordinate
        self.diameter = diameter
        super.init()
    }
}

struct MeasurementResult {
    enum MeasurementType {
        case distance
        case area
    }

    let type: MeasurementType
    let value: Double
    let unit: String
    let displayValue: String
    var perimeter: Double?
}

// MARK: - Map Overlay Extensions

extension WorkAreaPolygon {
    func toOverlay() -> MKPolygon {
        let overlay = MKPolygon(coordinates: points, count: points.count)
        overlay.title = name
        overlay.subtitle = serviceType.rawValue
        return overlay
    }
}

extension TreeMarker {
    var title: String? {
        return species ?? "Tree"
    }

    var subtitle: String? {
        if let dbh = dbh, let height = height {
            return "DBH: \(Int(dbh))\" | Height: \(Int(height))'"
        }
        return nil
    }
}

extension StumpMarker {
    var title: String? {
        return "Stump"
    }

    var subtitle: String? {
        if let diameter = diameter {
            return "Diameter: \(Int(diameter))\""
        }
        return nil
    }
}