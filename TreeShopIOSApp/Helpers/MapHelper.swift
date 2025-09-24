import Foundation
import MapKit
import SwiftUI

// MARK: - Map Helper for Native Maps Integration
struct MapHelper {

    // Open address in Apple Maps
    static func openInMaps(address: String, name: String? = nil) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                print("Could not geocode address: \(address)")
                return
            }

            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            mapItem.name = name ?? address
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        }
    }

    // Open coordinates in Apple Maps
    static func openInMaps(latitude: Double, longitude: Double, name: String? = nil) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = name ?? "Location"
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    // Get directions to address
    static func getDirections(to address: String, name: String? = nil) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                print("Could not geocode address: \(address)")
                return
            }

            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            mapItem.name = name ?? address

            MKMapItem.openMaps(with: [MKMapItem.forCurrentLocation(), mapItem],
                             launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
    }

    // Open multiple customers in Maps
    static func openMultipleInMaps(customers: [CDCustomer]) {
        var mapItems: [MKMapItem] = []

        for customer in customers {
            if customer.latitude != 0 && customer.longitude != 0 {
                let coordinate = CLLocationCoordinate2D(
                    latitude: customer.latitude,
                    longitude: customer.longitude
                )
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                mapItem.name = customer.name
                mapItems.append(mapItem)
            }
        }

        if !mapItems.isEmpty {
            MKMapItem.openMaps(with: mapItems, launchOptions: nil)
        }
    }
}

// MARK: - Map Button Component
struct OpenInMapsButton: View {
    let address: String?
    let latitude: Double
    let longitude: Double
    let name: String?
    var style: ButtonStyle = .primary

    enum ButtonStyle {
        case primary
        case compact
        case inline
    }

    var body: some View {
        if style == .primary {
            Button(action: openInMaps) {
                Label("Get Directions", systemImage: "map.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasValidLocation)
        } else if style == .compact {
            Button(action: openInMaps) {
                Image(systemName: "map.fill")
            }
            .disabled(!hasValidLocation)
        } else {
            Button(action: openInMaps) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.caption)
                    Text("Directions")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .disabled(!hasValidLocation)
        }
    }

    var hasValidLocation: Bool {
        if latitude != 0 && longitude != 0 {
            return true
        }
        return address != nil && !address!.isEmpty
    }

    func openInMaps() {
        if latitude != 0 && longitude != 0 {
            MapHelper.openInMaps(latitude: latitude, longitude: longitude, name: name)
        } else if let address = address, !address.isEmpty {
            MapHelper.getDirections(to: address, name: name)
        }
    }
}

// MARK: - View Extension for Easy Integration
extension View {
    func mapButton(address: String?, latitude: Double = 0, longitude: Double = 0, name: String? = nil) -> some View {
        self.overlay(
            OpenInMapsButton(
                address: address,
                latitude: latitude,
                longitude: longitude,
                name: name,
                style: .inline
            ),
            alignment: .topTrailing
        )
    }
}