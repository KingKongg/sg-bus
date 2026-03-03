import SwiftUI

struct BusStopDetailView: View {
    let stop: BusStop

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var favouritesManager: FavouritesManager
    @Environment(\.busService) private var busService
    @StateObject private var viewModel: BusStopDetailViewModel

    init(stop: BusStop) {
        self.stop = stop
        _viewModel = StateObject(wrappedValue: BusStopDetailViewModel(stop: stop))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.id)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(theme.textMuted)
                    Text(stop.name)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    Text(stop.road)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, 16)

                // Services header
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .modifier(PulsingModifier())
                    Text("All services")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(theme.textPrimary)
                }
                .padding(.horizontal, 16)

                // Arrival rows
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.arrivals) { arrival in
                        NavigationLink {
                            BusDetailView(serviceNo: arrival.serviceNo)
                        } label: {
                            BusArrivalRow(
                                arrival: arrival,
                                isFavourite: favouritesManager.isFavourite(arrival.serviceNo),
                                onToggleFavourite: {
                                    withAnimation { favouritesManager.toggleFavourite(arrival.serviceNo) }
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
            .padding(.vertical, 16)
        }
        .background(theme.background)
        .navigationTitle(stop.name)
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.loadArrivals(service: busService)
        }
        .task {
            await viewModel.loadArrivals(service: busService)
        }
    }
}
