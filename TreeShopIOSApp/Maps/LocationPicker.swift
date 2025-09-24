import SwiftUI
import MapKit
import CoreLocation

struct LocationPicker: View {
    @Binding var address: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    @State private var searchText = ""
    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Map View
                Map(position: $mapPosition) {
                    UserAnnotation()

                    ForEach(annotations) { item in
                        Marker(
                            "Selected Location",
                            coordinate: item.coordinate
                        )
                        .tint(.blue)
                    }
                }
                .onMapCameraChange { mapCameraUpdateContext in
                    // Could handle map camera changes if needed
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }

                // Search overlay
                VStack {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Search address...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                searchLocation()
                            }

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
                    .padding()

                    // Search results
                    if !searchResults.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(searchResults, id: \.self) { item in
                                    Button(action: {
                                        selectSearchResult(item)
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name ?? "Unknown")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            if let address = item.placemark.title {
                                                Text(address)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    Divider()
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                        .frame(maxHeight: 200)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer()

                    // Selected location info
                    if selectedLocation != nil {
                        VStack(spacing: 12) {
                            Text(address.isEmpty ? "Location selected" : address)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)

                            Button(action: confirmLocation) {
                                Label("Use This Location", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedLocation != nil {
                        Button("Done") {
                            confirmLocation()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                setupInitialLocation()
            }
        }
    }

    // MARK: - Helper Properties

    var annotations: [LocationAnnotation] {
        guard let location = selectedLocation else { return [] }
        return [LocationAnnotation(coordinate: location)]
    }

    // MARK: - Actions

    func setupInitialLocation() {
        // If we have existing coordinates, use them
        if latitude != 0 && longitude != 0 {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            mapPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
            selectedLocation = coordinate
        } else {
            // Try to geocode the address if we have one
            if !address.isEmpty {
                geocodeAddress(address)
            }
        }
    }

    func searchLocation() {
        guard !searchText.isEmpty else { return }

        isSearching = true
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText

        // Use a default region for search - ideally would extract from mapPosition
        searchRequest.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            isSearching = false

            if let response = response {
                searchResults = response.mapItems
            } else {
                searchResults = []
            }
        }
    }

    func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        selectedLocation = coordinate
        mapPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )

        // Update address
        if let name = item.name,
           let city = item.placemark.locality,
           let state = item.placemark.administrativeArea {
            address = "\(name), \(city), \(state)"
        } else if let formattedAddress = item.placemark.title {
            address = formattedAddress
        }

        searchResults = []
        searchText = ""
    }

    func handleMapTap(_ location: CGPoint) {
        // This would need conversion from screen coordinates to map coordinates
        // For now, we'll use a gesture recognizer approach
    }

    func geocodeAddress(_ addressString: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { placemarks, error in
            if let placemark = placemarks?.first,
               let location = placemark.location {
                let coordinate = location.coordinate
                selectedLocation = coordinate
                mapPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
                latitude = coordinate.latitude
                longitude = coordinate.longitude
            }
        }
    }

    func confirmLocation() {
        if let location = selectedLocation {
            latitude = location.latitude
            longitude = location.longitude

            // If address is empty, reverse geocode to get it
            if address.isEmpty {
                let geocoder = CLGeocoder()
                let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
                    if let placemark = placemarks?.first {
                        var components: [String] = []

                        if let street = placemark.thoroughfare {
                            if let number = placemark.subThoroughfare {
                                components.append("\(number) \(street)")
                            } else {
                                components.append(street)
                            }
                        }

                        if let city = placemark.locality {
                            components.append(city)
                        }

                        if let state = placemark.administrativeArea {
                            components.append(state)
                        }

                        if let zip = placemark.postalCode {
                            components.append(zip)
                        }

                        address = components.joined(separator: ", ")
                    }
                    dismiss()
                }
            } else {
                dismiss()
            }
        }
    }
}

struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Integration Helper

struct LocationPickerButton: View {
    @Binding var address: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    @State private var showingPicker = false

    var body: some View {
        Button(action: { showingPicker = true }) {
            HStack {
                Image(systemName: latitude != 0 ? "mappin.circle.fill" : "mappin.circle")
                    .foregroundColor(latitude != 0 ? .green : .blue)

                VStack(alignment: .leading) {
                    Text(latitude != 0 ? "Location Set" : "Set Location")
                        .font(.subheadline)
                    if latitude != 0 {
                        Text("\(latitude, specifier: "%.4f"), \(longitude, specifier: "%.4f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .sheet(isPresented: $showingPicker) {
            LocationPicker(
                address: $address,
                latitude: $latitude,
                longitude: $longitude
            )
        }
    }
}

#Preview {
    LocationPicker(
        address: .constant(""),
        latitude: .constant(0),
        longitude: .constant(0)
    )
}