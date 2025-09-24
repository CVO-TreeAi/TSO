import SwiftUI
import MapKit
import CoreLocation
import CoreData

// MARK: - Advanced Work Order Map View
// Integrates TreeScore GPS mapping with Work Order management
// Full polygon drawing, tree/stump marking, and address autocomplete

struct AdvancedWorkOrderMapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let workOrders: [CDWorkOrder]

    @StateObject private var drawingManager = DrawingManager()
    @StateObject private var addressSearchManager = AddressSearchManager()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var selectedWorkOrder: CDWorkOrder?
    @State private var selectedTree: TreeInventoryItem?
    @State private var mapType: MKMapType = .hybrid // Default to hybrid as requested
    @State private var showingTreeScoreMode = false
    @State private var showingMeasurementMode = false
    @State private var showingPropertyAnalysis = false
    @State private var currentTrees: [TreeInventoryItem] = []
    @State private var showingPricingCalculator = false
    @State private var showingPolygonNaming = false
    @State private var pendingPolygonName = ""
    @State private var pendingServiceType: ServiceType = .clearing
    @State private var showingAddressSearch = false

    var body: some View {
        ZStack {
            // Map View with Drawing Support
            MapViewRepresentable(
                region: $region,
                workOrders: workOrders,
                trees: currentTrees,
                selectedWorkOrder: $selectedWorkOrder,
                selectedTree: $selectedTree,
                mapType: mapType,
                showTreeScores: showingTreeScoreMode,
                drawingManager: drawingManager
            )
            .ignoresSafeArea()

            // Drawing Controls Overlay
            VStack {
                // Top Controls Bar
                HStack {
                    // Map Type Selector (Hybrid default)
                    MapTypeSelector(mapType: $mapType)
                        .padding(.leading)

                    Spacer()

                    // Address Search Button
                    Button(action: { showingAddressSearch = true }) {
                        Image(systemName: "magnifyingglass")
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    // TreeScore Toggle
                    Button(action: { showingTreeScoreMode.toggle() }) {
                        Label("TreeScore", systemImage: showingTreeScoreMode ? "tree.fill" : "tree")
                            .padding(8)
                            .background(showingTreeScoreMode ? Color.green : Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    // Measurement Mode
                    Button(action: {
                        if drawingManager.currentMode == .measuring {
                            drawingManager.cancelDrawing()
                        } else {
                            drawingManager.startMeasuring()
                        }
                    }) {
                        Label("Measure", systemImage: drawingManager.currentMode == .measuring ? "ruler.fill" : "ruler")
                            .padding(8)
                            .background(drawingManager.currentMode == .measuring ? Color.orange : Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.trailing)
                }
                .padding(.top, 50)

                // Drawing Mode Controls
                if drawingManager.currentMode != .none {
                    DrawingControlsBar(
                        drawingManager: drawingManager,
                        onFinishPolygon: {
                            showingPolygonNaming = true
                        }
                    )
                    .padding()
                }

                Spacer()

                // Active Drawing Info
                if drawingManager.isDrawing {
                    ActiveDrawingInfo(drawingManager: drawingManager)
                        .padding()
                }

                // Measurement Result
                if let measurement = drawingManager.currentMeasurement {
                    MeasurementResultView(measurement: measurement)
                        .padding()
                }

                // Bottom Info Panel
                if let workOrder = selectedWorkOrder {
                    WorkOrderMapDetailCard(
                        workOrder: workOrder,
                        trees: currentTrees,
                        polygons: drawingManager.workAreaPolygons,
                        onCalculatePrice: {
                            showingPricingCalculator = true
                        },
                        onPropertyAnalysis: {
                            showingPropertyAnalysis = true
                        },
                        onCreateLineItem: { polygon in
                            createLineItemFromPolygon(polygon, for: workOrder)
                        }
                    )
                    .padding()
                    .transition(.move(edge: .bottom))
                }

                if let tree = selectedTree {
                    TreeDetailCard(tree: tree)
                        .padding()
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .sheet(isPresented: $showingPolygonNaming) {
            PolygonNamingSheet(
                name: $pendingPolygonName,
                serviceType: $pendingServiceType,
                onSave: {
                    drawingManager.finishPolygon(
                        name: pendingPolygonName,
                        serviceType: pendingServiceType
                    )
                    pendingPolygonName = ""
                    showingPolygonNaming = false
                },
                onCancel: {
                    drawingManager.cancelDrawing()
                    showingPolygonNaming = false
                }
            )
        }
        .sheet(isPresented: $showingAddressSearch) {
            AddressSearchSheet(
                address: .constant(""),
                latitude: .constant(0),
                longitude: .constant(0),
                onSelection: { address, coordinate in
                    if let coord = coordinate {
                        region.center = coord
                        region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    }
                    showingAddressSearch = false
                }
            )
        }
        .sheet(isPresented: $showingPricingCalculator) {
            if let workOrder = selectedWorkOrder {
                OpsPricingCalculatorView(
                    workOrder: workOrder,
                    trees: currentTrees
                )
                .environment(\.managedObjectContext, viewContext)
            }
        }
        .sheet(isPresented: $showingPropertyAnalysis) {
            if let workOrder = selectedWorkOrder {
                PropertyAnalysisView(
                    workOrder: workOrder,
                    trees: currentTrees
                )
            }
        }
        .onAppear {
            centerMapOnWorkOrders()
            loadTreeInventory()
        }
    }

    func centerMapOnWorkOrders() {
        let workOrdersWithLocation = workOrders.filter { workOrder in
            guard let customer = workOrder.customer else { return false }
            return customer.latitude != 0 && customer.longitude != 0
        }

        if let firstWorkOrder = workOrdersWithLocation.first,
           let customer = firstWorkOrder.customer {
            region.center = CLLocationCoordinate2D(
                latitude: customer.latitude,
                longitude: customer.longitude
            )
        }
    }

    func loadTreeInventory() {
        // Load tree inventory for selected work order's property
        if let workOrder = selectedWorkOrder,
           let customer = workOrder.customer {

            var trees: [TreeInventoryItem] = []
            let baseCoordinate = CLLocationCoordinate2D(
                latitude: customer.latitude,
                longitude: customer.longitude
            )

            // Generate sample trees around the property
            for i in 0..<5 {
                let offset = Double(i) * 0.0001
                let tree = TreeInventoryItem(
                    coordinate: CLLocationCoordinate2D(
                        latitude: baseCoordinate.latitude + offset,
                        longitude: baseCoordinate.longitude + offset
                    ),
                    gpsAccuracy: 5.0,
                    height: Double.random(in: 30...80),
                    canopyRadius: Double.random(in: 10...30),
                    dbh: Double.random(in: 12...36),
                    afissPercentage: Double.random(in: 0...30),
                    species: ["Oak", "Pine", "Maple", "Birch", "Cedar"][i % 5],
                    healthStatus: ["Good", "Fair", "Poor"][i % 3]
                )
                trees.append(tree)
            }

            currentTrees = trees
        }
    }

    func createLineItemFromPolygon(_ polygon: WorkAreaPolygon, for workOrder: CDWorkOrder) {
        // Create a new line item from the polygon
        let lineItem = CDLineItem(context: viewContext)
        lineItem.id = UUID()
        lineItem.proposal = workOrder.proposal
        lineItem.itemDescription = "\(polygon.name) - \(polygon.serviceType.rawValue)"
        lineItem.serviceType = polygon.serviceType.rawValue
        lineItem.quantity = 1

        // Calculate pricing based on area
        let pricing = drawingManager.calculatePricingForPolygon(polygon)
        lineItem.unitPrice = pricing
        lineItem.totalPrice = pricing

        // Store polygon data for future use
        // TODO: Add custom field to Core Data model for polygon data
        let polygonData = drawingManager.exportPolygonToLineItem(polygon)
        if let jsonData = try? JSONSerialization.data(withJSONObject: polygonData),
           let _ = String(data: jsonData, encoding: .utf8) {
            // For now, append polygon info to item description
            lineItem.itemDescription = "\(polygon.name) - \(polygon.serviceType.rawValue)\nArea: \(polygonData["areaFormatted"] ?? "")"
        }

        // Save context
        do {
            try viewContext.save()
        } catch {
            print("Error saving line item: \(error)")
        }
    }
}

// MARK: - Enhanced Map View UIKit Representable with Drawing Support
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let workOrders: [CDWorkOrder]
    let trees: [TreeInventoryItem]
    @Binding var selectedWorkOrder: CDWorkOrder?
    @Binding var selectedTree: TreeInventoryItem?
    let mapType: MKMapType
    let showTreeScores: Bool
    @ObservedObject var drawingManager: DrawingManager

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.mapType = mapType // Set initial map type

        // Add tap gesture for drawing
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleMapTap(_:))
        )
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        mapView.setRegion(region, animated: true)

        // Update annotations
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Add work order annotations
        for workOrder in workOrders {
            if let customer = workOrder.customer,
               customer.latitude != 0 && customer.longitude != 0 {
                let annotation = WorkOrderAnnotation(workOrder: workOrder)
                mapView.addAnnotation(annotation)
            }
        }

        // Add tree annotations if in TreeScore mode
        if showTreeScores {
            for tree in trees {
                mapView.addAnnotation(tree)
            }
        }

        // Add tree markers from drawing manager
        for treeMarker in drawingManager.treeMarkers {
            mapView.addAnnotation(treeMarker)
        }

        // Add stump markers from drawing manager
        for stumpMarker in drawingManager.stumpMarkers {
            mapView.addAnnotation(stumpMarker)
        }

        // Add completed work area polygons
        for workArea in drawingManager.workAreaPolygons {
            mapView.addOverlay(workArea.toOverlay())
        }

        // Add current drawing polygon
        if drawingManager.currentMode == .polygon && drawingManager.currentPolygonPoints.count > 1 {
            let polygon = MKPolygon(
                coordinates: drawingManager.currentPolygonPoints,
                count: drawingManager.currentPolygonPoints.count
            )
            mapView.addOverlay(polygon)
        }

        // Add measurement overlay
        if drawingManager.currentMode == .measuring && drawingManager.measurementPoints.count >= 2 {
            if drawingManager.measurementPoints.count == 2 {
                // Draw line for distance
                let polyline = MKPolyline(
                    coordinates: drawingManager.measurementPoints,
                    count: drawingManager.measurementPoints.count
                )
                mapView.addOverlay(polyline)
            } else {
                // Draw polygon for area
                let polygon = MKPolygon(
                    coordinates: drawingManager.measurementPoints,
                    count: drawingManager.measurementPoints.count
                )
                mapView.addOverlay(polygon)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            switch parent.drawingManager.currentMode {
            case .polygon:
                parent.drawingManager.addPolygonPoint(coordinate)
            case .tree:
                parent.drawingManager.addTreeMarker(at: coordinate)
            case .stump:
                parent.drawingManager.addStumpMarker(at: coordinate)
            case .measuring:
                parent.drawingManager.addMeasurementPoint(coordinate)
            case .none:
                break
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)

                // Check if it's a work area polygon
                if let _ = polygon.title,
                   let serviceTypeRaw = polygon.subtitle,
                   let serviceType = ServiceType(rawValue: serviceTypeRaw) {
                    // Completed work area
                    renderer.fillColor = serviceTypeColor(serviceType).withAlphaComponent(0.3)
                    renderer.strokeColor = serviceTypeColor(serviceType)
                    renderer.lineWidth = 2
                } else if parent.drawingManager.currentMode == .measuring {
                    // Measurement area
                    renderer.fillColor = UIColor.orange.withAlphaComponent(0.2)
                    renderer.strokeColor = UIColor.orange
                    renderer.lineWidth = 2
                    renderer.lineDashPattern = [5, 5]
                } else {
                    // Current drawing polygon
                    renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                    renderer.strokeColor = UIColor.blue
                    renderer.lineWidth = 2
                    renderer.lineDashPattern = [10, 5]
                }

                return renderer
            }

            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.orange
                renderer.lineWidth = 3
                renderer.lineDashPattern = [5, 5]
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        func serviceTypeColor(_ type: ServiceType) -> UIColor {
            switch type {
            case .clearing:
                return .systemRed
            case .thinning:
                return .systemGreen
            case .removal:
                return .systemBlue
            case .pruning:
                return .systemPurple
            case .emergency:
                return .systemOrange
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }

            if let workOrderAnnotation = annotation as? WorkOrderAnnotation {
                let identifier = "WorkOrder"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }

                if let markerView = annotationView as? MKMarkerAnnotationView {
                    markerView.glyphImage = UIImage(systemName: "wrench.and.screwdriver.fill")
                    markerView.markerTintColor = priorityColor(for: workOrderAnnotation.workOrder)
                }

                return annotationView
            }

            if let tree = annotation as? TreeInventoryItem {
                let identifier = "Tree"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }

                if let markerView = annotationView as? MKMarkerAnnotationView {
                    markerView.glyphImage = UIImage(systemName: tree.complexity.iconName)
                    markerView.markerTintColor = complexityColor(for: tree.complexity)
                }

                return annotationView
            }

            if annotation is TreeMarker {
                let identifier = "TreeMarker"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }

                if let markerView = annotationView as? MKMarkerAnnotationView {
                    markerView.glyphImage = UIImage(systemName: "tree.fill")
                    markerView.markerTintColor = .systemGreen
                }

                return annotationView
            }

            if annotation is StumpMarker {
                let identifier = "StumpMarker"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }

                if let markerView = annotationView as? MKMarkerAnnotationView {
                    markerView.glyphImage = UIImage(systemName: "circle.dashed")
                    markerView.markerTintColor = .systemBrown
                }

                return annotationView
            }

            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let workOrderAnnotation = view.annotation as? WorkOrderAnnotation {
                parent.selectedWorkOrder = workOrderAnnotation.workOrder
                parent.selectedTree = nil
            } else if let tree = view.annotation as? TreeInventoryItem {
                parent.selectedTree = tree
                parent.selectedWorkOrder = nil
            }
        }

        func priorityColor(for workOrder: CDWorkOrder) -> UIColor {
            switch workOrder.priority {
            case 1: return .systemRed
            case 2: return .systemOrange
            case 3: return .systemBlue
            default: return .systemGray
            }
        }

        func complexityColor(for complexity: TreeComplexity) -> UIColor {
            switch complexity {
            case .low: return .systemGreen
            case .medium: return .systemOrange
            case .high: return .systemRed
            case .extreme: return .systemPurple
            }
        }
    }
}

// MARK: - Drawing Controls Bar
struct DrawingControlsBar: View {
    @ObservedObject var drawingManager: DrawingManager
    let onFinishPolygon: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Drawing mode buttons
            Button(action: { drawingManager.startDrawingPolygon() }) {
                Label("Polygon", systemImage: "square.dashed")
                    .padding(8)
                    .background(drawingManager.currentMode == .polygon ? Color.blue : Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: { drawingManager.currentMode = .tree }) {
                Label("Tree", systemImage: "tree")
                    .padding(8)
                    .background(drawingManager.currentMode == .tree ? Color.green : Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: { drawingManager.currentMode = .stump }) {
                Label("Stump", systemImage: "circle.dashed")
                    .padding(8)
                    .background(drawingManager.currentMode == .stump ? Color.brown : Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Spacer()

            // Action buttons
            if drawingManager.currentMode == .polygon && drawingManager.currentPolygonPoints.count >= 3 {
                Button(action: onFinishPolygon) {
                    Label("Finish", systemImage: "checkmark.circle.fill")
                        .padding(8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            Button(action: { drawingManager.cancelDrawing() }) {
                Label("Cancel", systemImage: "xmark.circle.fill")
                    .padding(8)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Active Drawing Info
struct ActiveDrawingInfo: View {
    @ObservedObject var drawingManager: DrawingManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch drawingManager.currentMode {
            case .polygon:
                Text("Drawing Polygon")
                    .font(.headline)
                Text("\(drawingManager.currentPolygonPoints.count) points")
                    .font(.caption)
                if drawingManager.currentPolygonPoints.count < 3 {
                    Text("Add \(3 - drawingManager.currentPolygonPoints.count) more points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            case .tree:
                Text("Placing Trees")
                    .font(.headline)
                Text("Tap to add tree markers")
                    .font(.caption)
            case .stump:
                Text("Placing Stumps")
                    .font(.headline)
                Text("Tap to add stump markers")
                    .font(.caption)
            case .measuring:
                Text("Measuring")
                    .font(.headline)
                Text("\(drawingManager.measurementPoints.count) points")
                    .font(.caption)
            case .none:
                EmptyView()
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(8)
    }
}

// MARK: - Measurement Result View
struct MeasurementResultView: View {
    let measurement: MeasurementResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(measurement.type == .distance ? "Distance" : "Area")
                .font(.headline)
            Text(measurement.displayValue)
                .font(.title2)
                .fontWeight(.bold)
            if let perimeter = measurement.perimeter {
                Text("Perimeter: \(String(format: "%.1f m", perimeter))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(8)
    }
}

// MARK: - Polygon Naming Sheet
struct PolygonNamingSheet: View {
    @Binding var name: String
    @Binding var serviceType: ServiceType
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Work Area Details") {
                    TextField("Area Name", text: $name)

                    Picker("Service Type", selection: $serviceType) {
                        Text("Land Clearing").tag(ServiceType.clearing)
                        Text("Forestry Thinning").tag(ServiceType.thinning)
                        Text("Tree Removal").tag(ServiceType.removal)
                        Text("Pruning").tag(ServiceType.pruning)
                        Text("Emergency").tag(ServiceType.emergency)
                    }
                }
            }
            .navigationTitle("Name Work Area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: onSave)
                        .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Enhanced Work Order Map Detail Card
struct WorkOrderMapDetailCard: View {
    @ObservedObject var workOrder: CDWorkOrder
    let trees: [TreeInventoryItem]
    let polygons: [WorkAreaPolygon]
    let onCalculatePrice: () -> Void
    let onPropertyAnalysis: () -> Void
    let onCreateLineItem: (WorkAreaPolygon) -> Void

    var totalTreeScore: Double {
        trees.reduce(0) { $0 + $1.treeScore.finalTreeScore }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(workOrder.customer?.name ?? "Unknown")
                        .font(.headline)
                    Text("WO #\(workOrder.workOrderNumber ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(workOrder.priorityLevel)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }

            // TreeScore Summary
            if !trees.isEmpty {
                HStack {
                    Label("\(trees.count) Trees", systemImage: "tree.fill")
                        .font(.caption)

                    Spacer()

                    Text("Total TreeScore: \(Int(totalTreeScore))")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 4)
            }

            // Work Area Polygons
            if !polygons.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Work Areas (\(polygons.count))")
                        .font(.caption)
                        .fontWeight(.semibold)

                    ForEach(polygons) { polygon in
                        HStack {
                            Text(polygon.name)
                                .font(.caption)
                            Spacer()
                            Text(polygon.serviceType.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Button(action: { onCreateLineItem(polygon) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Actions
            HStack(spacing: 12) {
                Button(action: onCalculatePrice) {
                    Label("Calculate Price", systemImage: "dollarsign.circle.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(action: onPropertyAnalysis) {
                    Label("Property Analysis", systemImage: "chart.pie.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }

    var priorityColor: Color {
        switch workOrder.priority {
        case 1: return .red
        case 2: return .orange
        case 3: return .blue
        default: return .gray
        }
    }
}

// MARK: - Work Order Annotation
class WorkOrderAnnotation: NSObject, MKAnnotation {
    let workOrder: CDWorkOrder

    var coordinate: CLLocationCoordinate2D {
        if let customer = workOrder.customer {
            return CLLocationCoordinate2D(
                latitude: customer.latitude,
                longitude: customer.longitude
            )
        }
        return CLLocationCoordinate2D()
    }

    var title: String? {
        return workOrder.customer?.name ?? "Unknown Customer"
    }

    var subtitle: String? {
        return "WO #\(workOrder.workOrderNumber ?? "") • \(workOrder.priorityLevel)"
    }

    init(workOrder: CDWorkOrder) {
        self.workOrder = workOrder
    }
}

// MARK: - Map Type Selector
struct MapTypeSelector: View {
    @Binding var mapType: MKMapType

    var body: some View {
        Menu {
            Button("Standard") { mapType = .standard }
            Button("Satellite") { mapType = .satellite }
            Button("Hybrid") { mapType = .hybrid }
        } label: {
            Image(systemName: "map")
                .padding(8)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}

// MARK: - Tree Detail Card
struct TreeDetailCard: View {
    let tree: TreeInventoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: tree.complexity.iconName)
                    .foregroundColor(Color(hex: tree.complexity.color))
                Text(tree.species ?? "Unknown Species")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Height")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(tree.height)) ft")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading) {
                    Text("DBH")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(tree.dbh)) in")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading) {
                    Text("TreeScore")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", tree.treeScore.finalTreeScore))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: tree.complexity.color))
                }

                VStack(alignment: .leading) {
                    Text("AFISS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(tree.afissPercentage))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            if let health = tree.healthStatus {
                Text("Health: \(health)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}