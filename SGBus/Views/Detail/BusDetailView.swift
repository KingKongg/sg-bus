import MapKit
import SwiftUI

struct BusDetailView: View {
    let serviceNo: String

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var favouritesManager: FavouritesManager
    @EnvironmentObject private var pinManager: PinManager
    @Environment(\.busService) private var busService
    @StateObject private var viewModel: BusDetailViewModel
    @State private var showRouteMap = false
    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var isFavourited: Bool {
        favouritesManager.isFavourite(serviceNo)
    }

    init(serviceNo: String) {
        self.serviceNo = serviceNo
        _viewModel = StateObject(wrappedValue: BusDetailViewModel(serviceNo: serviceNo))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Bus number + star
                HStack(alignment: .top) {
                    Text(serviceNo)
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    VStack(spacing: 4) {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.easeOut(duration: 0.2)) {
                                let stopCode = viewModel.serviceDetail?.routeStops.first?.id ?? ""
                                favouritesManager.toggleFavourite(serviceNo, stopCode: stopCode)
                            }
                        } label: {
                            Image(systemName: isFavourited ? "star.fill" : "star")
                                .font(.system(.title, design: .monospaced))
                                .foregroundColor(isFavourited ? theme.star : theme.textMuted)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(isFavourited ? "Remove from favourites" : "Add to favourites")

                        Button {
                            if pinManager.isPinned(serviceNo) {
                                pinManager.unpin()
                            } else if let detail = viewModel.serviceDetail, let arrival = viewModel.arrival {
                                pinManager.pin(
                                    serviceNo: serviceNo,
                                    destination: detail.destination,
                                    stopName: detail.routeStops.first?.name ?? detail.origin,
                                    stopCode: detail.routeStops.first?.id ?? "",
                                    busService: busService,
                                    initialArrival: arrival
                                )
                            }
                        } label: {
                            Image(systemName: pinManager.isPinned(serviceNo) ? "pin.fill" : "pin")
                                .font(.system(.title3, design: .monospaced))
                                .foregroundColor(pinManager.isPinned(serviceNo) ? theme.accent : theme.textMuted)
                                .frame(width: 44, height: 44)
                        }
                        .disabled(viewModel.arrival == nil)
                        .accessibilityLabel(pinManager.isPinned(serviceNo) ? "Unpin from Dynamic Island" : "Pin to Dynamic Island")
                    }
                }

                // Route text
                if let detail = viewModel.serviceDetail {
                    Text("\(detail.origin) → \(detail.destination)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(theme.textSecondary)

                    // Bus type + crowd
                    HStack(spacing: 8) {
                        BusTypeBadge(busType: viewModel.arrival?.busType ?? detail.busType)
                        if let arrival = viewModel.arrival {
                            BusOperatorBadge(busOperator: arrival.busOperator)
                        }
                        if let arrival = viewModel.arrival {
                            CrowdIndicator(crowdLevel: arrival.crowdLevel)
                            if arrival.isWheelchairAccessible {
                                Image(systemName: "figure.roll")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(theme.accent)
                                    .accessibilityLabel("Wheelchair accessible")
                            }
                        }
                    }
                }

                // Large arrival time
                if let arrival = viewModel.arrival {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(primaryArrivalText(arrival.nextBus))
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundColor(primaryArrivalColor(arrival.nextBus))

                        if !arrival.nextBus.isArriving {
                            Text("to arrival")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(theme.textSecondary)
                        }
                    }

                    // Next arrivals
                    nextArrivalsRow(arrival)
                }

                if viewModel.isLoading && viewModel.serviceDetail == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                }

                if let error = viewModel.error, viewModel.serviceDetail == nil {
                    Text(error)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(.vertical, 24)
                }

                Divider()
                    .background(theme.border)

                // Route section
                if let detail = viewModel.serviceDetail, !detail.routeStops.isEmpty {
                    HStack {
                        Text("ROUTE")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(theme.textSecondary)

                        Spacer()

                        Button {
                            showRouteMap = true
                        } label: {
                            Image(systemName: "map")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(theme.accent)
                        }
                    }
                    .padding(.top, 4)

                    routeList(stops: detail.routeStops)
                }
            }
            .padding(16)
        }
        .background(theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRouteMap) {
            if let detail = viewModel.serviceDetail {
                BusRouteMapView(
                    serviceNo: serviceNo,
                    routeStops: detail.routeStops,
                    arrival: viewModel.arrival
                )
                .environmentObject(theme)
            }
        }
        .refreshable {
            await viewModel.load(service: busService)
        }
        .task {
            await viewModel.load(service: busService)
        }
        .onReceive(refreshTimer) { _ in
            Task { await viewModel.refreshArrivals(service: busService) }
        }
    }

    // MARK: - Arrival helpers

    private func primaryArrivalText(_ time: ArrivalTime) -> String {
        guard let minutes = time.minutesAway else { return "-" }
        if minutes <= 0 { return "Arr" }
        return "\(minutes) min"
    }

    private func primaryArrivalColor(_ time: ArrivalTime) -> Color {
        if time.isArriving { return theme.arriving }
        if time.isSoon { return theme.soon }
        return theme.accent
    }

    private func nextArrivalsRow(_ arrival: BusArrival) -> some View {
        HStack(spacing: 0) {
            Text("Next: ")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(theme.textSecondary)

            if let min2 = arrival.nextBus2.minutesAway {
                Text(min2 <= 0 ? "Arr" : "\(min2) min")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
            } else {
                Text("-")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(theme.textSecondary)
            }

            if let min3 = arrival.nextBus3.minutesAway {
                Text(" · then ")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(theme.textSecondary)
                Text(min3 <= 0 ? "Arr" : "\(min3) min")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
            }
        }
    }

    // MARK: - Route list

    private func routeList(stops: [BusStop]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                VStack(alignment: .leading, spacing: 0) {
                    NavigationLink {
                        BusStopDetailView(stop: stop)
                    } label: {
                        HStack(alignment: .center, spacing: 16) {
                            // Dot
                            Circle()
                                .fill(theme.textMuted)
                                .frame(width: 8, height: 8)
                                .frame(width: 16)

                            // Stop name
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stop.name)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(theme.textPrimary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(theme.textMuted)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    // Connecting line + divider
                    if index < stops.count - 1 {
                        HStack(alignment: .top, spacing: 16) {
                            Rectangle()
                                .fill(theme.textMuted.opacity(0.4))
                                .frame(width: 2, height: 8)
                                .frame(width: 16)

                            Divider()
                                .background(theme.border)
                        }
                    }
                }
            }
        }
    }
}
