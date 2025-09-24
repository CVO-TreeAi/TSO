import Foundation
import MapKit
import Combine
import SwiftUI

// MARK: - Address Search Manager
// Provides app-wide address autocomplete functionality using MapKit
@MainActor
class AddressSearchManager: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var searchText = "" {
        didSet {
            if searchText != oldValue {
                searchAddresses()
            }
        }
    }

    @Published var searchResults: [AddressSearchResult] = []
    @Published var isSearching = false
    @Published var selectedAddress: AddressSearchResult?

    // MARK: - Private Properties
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchCancellable: AnyCancellable?
    private let searchSubject = PassthroughSubject<String, Never>()

    // Optional region to focus search
    var searchRegion: MKCoordinateRegion?

    override init() {
        super.init()
        setupSearchCompleter()
        setupDebouncing()
    }

    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        searchCompleter.pointOfInterestFilter = .includingAll
    }

    private func setupDebouncing() {
        // Debounce search to avoid excessive API calls
        searchCancellable = searchSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.performSearch(for: searchText)
            }
    }

    // MARK: - Search Methods

    func searchAddresses() {
        searchSubject.send(searchText)
    }

    private func performSearch(for query: String) {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchCompleter.queryFragment = query

        if let region = searchRegion {
            searchCompleter.region = region
        }
    }

    func selectAddress(_ result: AddressSearchResult, completion: @escaping (AddressSearchResult?) -> Void) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = result.title + " " + result.subtitle

        if let region = searchRegion {
            searchRequest.region = region
        }

        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] response, error in
            guard let response = response,
                  let item = response.mapItems.first else {
                completion(nil)
                return
            }

            let placemark = item.placemark
            let fullAddress = self?.formatAddress(from: placemark) ?? result.title

            let detailedResult = AddressSearchResult(
                title: result.title,
                subtitle: result.subtitle,
                fullAddress: fullAddress,
                coordinate: placemark.coordinate,
                placemark: placemark
            )

            DispatchQueue.main.async {
                self?.selectedAddress = detailedResult
                completion(detailedResult)
            }
        }
    }

    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []

        if let number = placemark.subThoroughfare {
            components.append(number)
        }

        if let street = placemark.thoroughfare {
            components.append(street)
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

        return components.joined(separator: ", ")
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        selectedAddress = nil
        isSearching = false
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension AddressSearchManager: MKLocalSearchCompleterDelegate {

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.searchResults = completer.results.map { completion in
                AddressSearchResult(
                    title: completion.title,
                    subtitle: completion.subtitle,
                    fullAddress: completion.title + " " + completion.subtitle,
                    coordinate: nil,
                    placemark: nil
                )
            }
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            print("Address search error: \(error)")
            self.isSearching = false
        }
    }
}

// MARK: - Data Models
struct AddressSearchResult: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let fullAddress: String
    var coordinate: CLLocationCoordinate2D?
    var placemark: CLPlacemark?

    static func == (lhs: AddressSearchResult, rhs: AddressSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Reusable Address Search Field Component
struct AddressSearchField: View {
    @Binding var address: String
    @Binding var latitude: Double
    @Binding var longitude: Double

    @StateObject private var searchManager = AddressSearchManager()
    @State private var isShowingResults = false
    @FocusState private var isFocused: Bool

    var placeholder: String = "Enter address..."
    var searchRegion: MKCoordinateRegion?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search Field
            HStack {
                Image(systemName: "location.magnifyingglass")
                    .foregroundColor(.secondary)

                TextField(placeholder, text: $searchManager.searchText)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onTapGesture {
                        isShowingResults = true
                    }
                    .onChange(of: searchManager.searchText) { oldValue, newValue in
                        if address != newValue {
                            address = newValue
                        }
                        isShowingResults = !newValue.isEmpty
                    }

                if searchManager.isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                if !searchManager.searchText.isEmpty {
                    Button(action: {
                        searchManager.clearSearch()
                        address = ""
                        latitude = 0
                        longitude = 0
                        isShowingResults = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)

            // Search Results
            if isShowingResults && !searchManager.searchResults.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(searchManager.searchResults) { result in
                            Button(action: {
                                selectAddress(result)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)

                            if result.id != searchManager.searchResults.last?.id {
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
                .frame(maxHeight: 200)
                .padding(.top, 4)
            }
        }
        .onAppear {
            if let region = searchRegion {
                searchManager.searchRegion = region
            }

            // Initialize with existing address if available
            if !address.isEmpty {
                searchManager.searchText = address
            }
        }
    }

    private func selectAddress(_ result: AddressSearchResult) {
        searchManager.selectAddress(result) { detailedResult in
            guard let result = detailedResult else { return }

            address = result.fullAddress
            if let coordinate = result.coordinate {
                latitude = coordinate.latitude
                longitude = coordinate.longitude
            }

            searchManager.searchText = result.fullAddress
            isShowingResults = false
            isFocused = false
        }
    }
}

// MARK: - Sheet Presentation Helper
struct AddressSearchSheet: View {
    @Binding var address: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Environment(\.dismiss) private var dismiss

    var onSelection: ((String, CLLocationCoordinate2D?) -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                AddressSearchField(
                    address: $address,
                    latitude: $latitude,
                    longitude: $longitude,
                    placeholder: "Search for address..."
                )
                .padding()

                if latitude != 0 && longitude != 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Selected Location", systemImage: "mappin.circle.fill")
                            .font(.headline)

                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Lat: \(latitude, specifier: "%.6f"), Lon: \(longitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                Spacer()

                if latitude != 0 && longitude != 0 {
                    Button(action: {
                        onSelection?(address, CLLocationCoordinate2D(
                            latitude: latitude,
                            longitude: longitude
                        ))
                        dismiss()
                    }) {
                        Text("Use This Address")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Address Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - View Modifier for Easy Integration
extension View {
    func addressAutocomplete(
        address: Binding<String>,
        latitude: Binding<Double>,
        longitude: Binding<Double>,
        placeholder: String = "Enter address...",
        region: MKCoordinateRegion? = nil
    ) -> some View {
        self.overlay(
            AddressSearchField(
                address: address,
                latitude: latitude,
                longitude: longitude,
                placeholder: placeholder,
                searchRegion: region
            )
        )
    }
}