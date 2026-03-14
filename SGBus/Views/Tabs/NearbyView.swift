import MapKit
import SwiftUI

struct NearbyView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var favouritesManager: FavouritesManager
    @Environment(\.busService) private var busService

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: LocationManager.singaporeCenter,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )
    )
    @State private var nearbyStops: [BusStop] = []
    @State private var selectedStop: BusStop?
    @State private var isLoadingStops = false
    @State private var selectedStopArrivals: [BusArrival] = []
    @State private var isLoadingArrivals = false
    @State private var selectedDetent: PresentationDetent = .fraction(0.4)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $position) {
                    UserAnnotation()

                    ForEach(nearbyStops) { stop in
                        if let lat = stop.latitude, let lng = stop.longitude {
                            Annotation(stop.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                                Button {
                                    selectStop(stop)
                                } label: {
                                    VStack(spacing: 2) {
                                        Circle()
                                            .fill(theme.accent)
                                            .frame(width: 12, height: 12)
                                            .overlay(
                                                Circle().stroke(theme.background, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .mapStyle(.standard)

                if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                    locationDeniedBanner
                }
            }
            .navigationTitle("Nearby")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedStop) { stop in
                stopSheet(stop)
                    .onAppear {
                        Task { await loadArrivals(for: stop) }
                    }
            }
            .onAppear {
                if locationManager.hasRealLocation {
                    centerOnUser()
                }
                locationManager.requestLocation()
            }
            .onChange(of: locationManager.currentLocation?.latitude) { _, _ in
                guard let loc = locationManager.currentLocation else { return }
                centerOnUser()
                Task { await loadNearbyStops(lat: loc.latitude, lng: loc.longitude) }
            }
            .task {
                if locationManager.hasRealLocation {
                    let loc = locationManager.effectiveLocation
                    await loadNearbyStops(lat: loc.latitude, lng: loc.longitude)
                }
            }
        }
    }

    // MARK: - Helpers

    private func centerOnUser() {
        let loc = locationManager.effectiveLocation
        withAnimation {
            position = .region(
                MKCoordinateRegion(
                    center: loc,
                    latitudinalMeters: 600,
                    longitudinalMeters: 600
                )
            )
        }
    }

    private func loadNearbyStops(lat: Double, lng: Double) async {
        isLoadingStops = true
        nearbyStops = await busService.getNearbyStops(latitude: lat, longitude: lng, radius: 300)
        isLoadingStops = false
    }

    private var locationDeniedBanner: some View {
        HStack {
            Image(systemName: "location.slash")
                .font(.system(.caption, design: .monospaced))
            Text("Location access denied. Enable in Settings to see nearby stops.")
                .font(.system(.caption, design: .monospaced))
        }
        .foregroundColor(theme.textPrimary)
        .padding(10)
        .background(theme.surface.opacity(0.95))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func selectStop(_ stop: BusStop) {
        if selectedStop != nil {
            // Dismiss current sheet, then re-present after a tick
            selectedStop = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                selectedDetent = .fraction(0.4)
                selectedStop = stop
            }
        } else {
            selectedDetent = .fraction(0.4)
            selectedStop = stop
        }
    }

    private func loadArrivals(for stop: BusStop) async {
        isLoadingArrivals = true
        selectedStopArrivals = []
        defer { isLoadingArrivals = false }
        do {
            selectedStopArrivals = try await busService.getArrivals(forStop: stop.id)
        } catch {
            selectedStopArrivals = []
        }
    }

    private func stopSheet(_ stop: BusStop) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stop.name)
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimary)

                        HStack(spacing: 6) {
                            Text("\(stop.road) · \(stop.id)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(theme.textSecondary)

                            if let dist = stop.distanceMetres {
                                Text("· \(dist)m away")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(theme.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Arrivals
                    if isLoadingArrivals {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(theme.textMuted)
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else if selectedStopArrivals.isEmpty {
                        Text("No buses operating at this time")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(theme.textMuted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(selectedStopArrivals) { arrival in
                                NavigationLink {
                                    BusDetailView(serviceNo: arrival.serviceNo)
                                } label: {
                                    BusArrivalRow(
                                        arrival: arrival,
                                        isFavourite: favouritesManager.isFavourite(serviceNo: arrival.serviceNo, stopCode: stop.id),
                                        onToggleFavourite: {
                                            withAnimation(.easeOut(duration: 0.2)) {
                                                favouritesManager.toggleFavourite(arrival.serviceNo, stopCode: stop.id)
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .background(theme.border)
                                    .padding(.leading, 84)
                            }
                        }
                    }
                }
                .padding(.top, 16)
            }
            .background(theme.background)
            .presentationDetents([.fraction(0.4), .large], selection: $selectedDetent)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
    }
}
