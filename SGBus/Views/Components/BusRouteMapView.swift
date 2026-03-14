import MapKit
import SwiftUI

struct BusRouteMapView: View {
    let serviceNo: String
    let routeStops: [BusStop]
    let arrival: BusArrival?

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Map {
                UserAnnotation()

                // Route polyline
                let coords = routeStops.compactMap { stop -> CLLocationCoordinate2D? in
                    guard let lat = stop.latitude, let lng = stop.longitude else { return nil }
                    return CLLocationCoordinate2D(latitude: lat, longitude: lng)
                }
                if coords.count >= 2 {
                    MapPolyline(coordinates: coords)
                        .stroke(theme.accent, lineWidth: 3)
                }

                // Stop annotations
                ForEach(Array(routeStops.enumerated()), id: \.element.id) { index, stop in
                    if let lat = stop.latitude, let lng = stop.longitude {
                        Annotation(
                            stop.name,
                            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                        ) {
                            Circle()
                                .fill(index == 0 ? theme.accent : theme.textMuted)
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(theme.background, lineWidth: 2))
                        }
                    }
                }

                // ETA marker
                if let etaCoord = estimatedBusCoordinate {
                    Annotation(
                        etaLabel,
                        coordinate: etaCoord
                    ) {
                        VStack(spacing: 2) {
                            Image(systemName: "bus.fill")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(theme.background)
                                .padding(4)
                                .background(theme.arriving)
                                .clipShape(Circle())
                            Text(etaLabel)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(theme.arriving)
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls {
                MapCompass()
                MapUserLocationButton()
            }
            .navigationTitle("Route \(serviceNo)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
    }

    // MARK: - ETA estimation

    private var etaLabel: String {
        guard let minutes = arrival?.nextBus.minutesAway else { return "" }
        if minutes <= 0 { return "Arr" }
        return "~\(minutes) min"
    }

    private var estimatedBusCoordinate: CLLocationCoordinate2D? {
        guard let arrival = arrival,
              arrival.nextBus.estimatedArrival != nil,
              let minutes = arrival.nextBus.minutesAway,
              routeStops.count >= 2,
              let firstLat = routeStops[0].latitude,
              let firstLng = routeStops[0].longitude else { return nil }

        let firstCoord = CLLocationCoordinate2D(latitude: firstLat, longitude: firstLng)

        // If arriving (0-1 min), place at first stop
        if minutes <= 1 {
            return firstCoord
        }

        // Interpolate slightly before stop[0] along reverse direction from stop[1]
        guard let secondLat = routeStops[1].latitude,
              let secondLng = routeStops[1].longitude else { return firstCoord }

        // Place bus marker before the first stop, in the reverse direction
        // The further away the bus, the further we offset (capped)
        let fraction = min(Double(minutes) / 30.0, 1.0) // normalize to 0-1 over 30 min
        let offsetLat = firstLat - (secondLat - firstLat) * fraction * 0.3
        let offsetLng = firstLng - (secondLng - firstLng) * fraction * 0.3

        return CLLocationCoordinate2D(latitude: offsetLat, longitude: offsetLng)
    }
}
