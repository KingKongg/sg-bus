import SwiftUI

struct BusDetailView: View {
    let serviceNo: String

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var favouritesManager: FavouritesManager
    @Environment(\.busService) private var busService
    @StateObject private var viewModel: BusDetailViewModel

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

                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.easeOut(duration: 0.2)) { favouritesManager.toggleFavourite(serviceNo) }
                    } label: {
                        Image(systemName: favouritesManager.isFavourite(serviceNo) ? "star.fill" : "star")
                            .font(.title)
                            .foregroundColor(favouritesManager.isFavourite(serviceNo) ? theme.star : theme.textMuted)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(favouritesManager.isFavourite(serviceNo) ? "Remove from favourites" : "Add to favourites")
                }

                // Route text
                if let detail = viewModel.serviceDetail {
                    Text("\(detail.origin) → \(detail.destination)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(theme.textSecondary)

                    // Bus type + crowd
                    HStack(spacing: 8) {
                        BusTypeBadge(busType: detail.busType)
                        if let arrival = viewModel.arrival {
                            CrowdIndicator(crowdLevel: arrival.crowdLevel)
                        }
                    }
                }

                // Large arrival time
                if let arrival = viewModel.arrival {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(primaryArrivalText(arrival.nextBus))
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundColor(primaryArrivalColor(arrival.nextBus))

                        Text("to arrival")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(theme.textSecondary)
                    }

                    // Next arrivals
                    nextArrivalsRow(arrival)
                }

                Divider()
                    .background(theme.border)

                // Route section
                if let detail = viewModel.serviceDetail, !detail.routeStops.isEmpty {
                    Text("ROUTE")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(theme.textSecondary)
                        .padding(.top, 4)

                    routeList(stops: detail.routeStops)
                }
            }
            .padding(16)
        }
        .background(theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.load(service: busService)
        }
        .task {
            await viewModel.load(service: busService)
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
                Text("\(min2) min")
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
                Text("\(min3) min")
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
                let isCurrent = stop.id == viewModel.serviceDetail?.routeStops.first?.id

                VStack(alignment: .leading, spacing: 0) {
                    NavigationLink {
                        BusStopDetailView(stop: stop)
                    } label: {
                        HStack(alignment: .center, spacing: 16) {
                            // Dot
                            Circle()
                                .fill(isCurrent ? theme.accent : theme.textMuted)
                                .frame(width: isCurrent ? 12 : 8, height: isCurrent ? 12 : 8)
                                .frame(width: 16)

                            // Stop name
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stop.name)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(isCurrent ? .bold : .regular)
                                    .foregroundColor(theme.textPrimary)

                                if isCurrent {
                                    Text("You are here")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(theme.accent)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.textMuted)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    // Connecting line + divider
                    HStack(alignment: .top, spacing: 16) {
                        if index < stops.count - 1 {
                            Rectangle()
                                .fill(theme.textMuted.opacity(0.4))
                                .frame(width: 2, height: 8)
                                .frame(width: 16)
                        }

                        Divider()
                            .background(theme.border)
                    }
                }
            }
        }
    }
}
