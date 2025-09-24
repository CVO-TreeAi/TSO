import SwiftUI
import MapKit
import CoreLocation
import CoreData

struct CustomerMapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDCustomer.name, ascending: true)],
        animation: .default)
    private var customers: FetchedResults<CDCustomer>

    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to SF
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    @State private var selectedCustomer: CDCustomer?
    @State private var showingCustomerDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $mapPosition) {
                    UserAnnotation()

                    ForEach(customerAnnotations) { annotation in
                        Annotation(
                            annotation.customer.name ?? "Customer",
                            coordinate: annotation.coordinate
                        ) {
                            CustomerMapPin(
                                customer: annotation.customer,
                                isSelected: selectedCustomer?.id == annotation.customer.id
                            )
                            .onTapGesture {
                                selectedCustomer = annotation.customer
                                showingCustomerDetail = true
                            }
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea(edges: .bottom)

                // Map controls overlay
                VStack {
                    Spacer()

                    HStack {
                        // Customer summary card on the left
                        if !customers.isEmpty {
                            CustomerMapSummary(
                                totalCustomers: customers.count,
                                selectedCustomer: selectedCustomer
                            )
                            .frame(maxWidth: 200)
                        }

                        Spacer()

                        // Map controls on the right
                        VStack(spacing: 10) {
                            // Center on user location
                            Button(action: centerOnUserLocation) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }

                            // Zoom controls
                            VStack(spacing: 0) {
                                Button(action: zoomIn) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.primary)
                                        .frame(width: 44, height: 44)
                                        .background(Color(.systemBackground))
                                }
                                Divider()
                                Button(action: zoomOut) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.primary)
                                        .frame(width: 44, height: 44)
                                        .background(Color(.systemBackground))
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 4)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Customer Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { fitAllCustomers() }) {
                            Label("Show All Customers", systemImage: "map")
                        }
                        Button(action: { /* Add filter */ }) {
                            Label("Filter by Status", systemImage: "line.horizontal.3.decrease.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCustomerDetail) {
                if let customer = selectedCustomer {
                    CustomerMapDetailView(customer: customer)
                }
            }
            .onAppear {
                requestLocationPermission()
                if let firstCustomer = customers.first,
                   let lat = firstCustomer.value(forKey: "latitude") as? Double,
                   let lon = firstCustomer.value(forKey: "longitude") as? Double,
                   lat != 0, lon != 0 {
                    mapPosition = .region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        )
                    )
                }
            }
        }
    }

    // MARK: - Helper Properties

    var customerAnnotations: [CustomerAnnotation] {
        customers.compactMap { customer in
            guard let lat = customer.value(forKey: "latitude") as? Double,
                  let lon = customer.value(forKey: "longitude") as? Double,
                  lat != 0, lon != 0 else { return nil }

            return CustomerAnnotation(
                customer: customer,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
            )
        }
    }

    // MARK: - Actions

    func centerOnUserLocation() {
        withAnimation {
            mapPosition = .userLocation(fallback: .automatic)
        }
    }

    func zoomIn() {
        // Since we're dealing with a MapCameraPosition, we need to handle this differently
        // For now, use automatic positioning
        withAnimation {
            // This is a simplified approach - ideally would extract and modify the region
            mapPosition = .automatic
        }
    }

    func zoomOut() {
        // Since we're dealing with a MapCameraPosition, we need to handle this differently
        // For now, use automatic positioning
        withAnimation {
            // This is a simplified approach - ideally would extract and modify the region
            mapPosition = .automatic
        }
    }

    func fitAllCustomers() {
        guard !customerAnnotations.isEmpty else { return }

        let coordinates = customerAnnotations.map { $0.coordinate }
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.2,
            longitudeDelta: (maxLon - minLon) * 1.2
        )

        withAnimation {
            mapPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }

    func requestLocationPermission() {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
    }
}

// MARK: - Supporting Types

struct CustomerAnnotation: Identifiable {
    let id = UUID()
    let customer: CDCustomer
    let coordinate: CLLocationCoordinate2D
}

struct CustomerMapPin: View {
    let customer: CDCustomer
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(isSelected ? .blue : .green)
                .background(Circle().fill(.white).frame(width: 36, height: 36))

            Image(systemName: "triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(isSelected ? .blue : .green)
                .rotationEffect(Angle(degrees: 180))
                .offset(y: -3)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct CustomerMapSummary: View {
    let totalCustomers: Int
    let selectedCustomer: CDCustomer?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let customer = selectedCustomer {
                Text(customer.name ?? "Unknown Customer")
                    .font(.headline)
                Text(customer.address ?? "No address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let proposalCount = customer.proposals?.count, proposalCount > 0 {
                    Text("\(proposalCount) proposal\(proposalCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            } else {
                Text("\(totalCustomers) Customer\(totalCustomers == 1 ? "" : "s")")
                    .font(.headline)
                Text("Tap a pin to see details")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

struct CustomerMapDetailView: View {
    let customer: CDCustomer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Customer info
                VStack(alignment: .leading, spacing: 8) {
                    Text(customer.name ?? "Unknown")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let address = customer.address {
                        Label(address, systemImage: "location")
                            .font(.subheadline)
                    }

                    if let phone = customer.phone {
                        Label(phone, systemImage: "phone")
                            .font(.subheadline)
                    }

                    if let email = customer.email {
                        Label(email, systemImage: "envelope")
                            .font(.subheadline)
                    }
                }
                .padding()

                // Actions
                VStack(spacing: 12) {
                    Button(action: { /* Open in Maps */ }) {
                        Label("Get Directions", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: { /* Create proposal */ }) {
                        Label("Create Proposal", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Customer Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CustomerMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}