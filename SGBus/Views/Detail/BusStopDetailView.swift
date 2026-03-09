import SwiftUI

struct BusStopDetailView: View {
    let stop: BusStop

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var favouritesManager: FavouritesManager
    @Environment(\.busService) private var busService
    @StateObject private var viewModel: BusStopDetailViewModel
    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var allServicesEnded: Bool {
        !viewModel.arrivals.isEmpty && viewModel.arrivals.allSatisfy { !$0.isOperating }
    }

    init(stop: BusStop) {
        self.stop = stop
        _viewModel = StateObject(wrappedValue: BusStopDetailViewModel(stop: stop))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Text(stop.id)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(theme.textMuted)
                    Text(stop.road)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, 16)

                // Error
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text(error)
                        Spacer()
                        Button("Retry") {
                            Task { await viewModel.loadArrivals(service: busService) }
                        }
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.red)
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 16)
                }

                // No buses message
                if !viewModel.isLoading && viewModel.arrivals.isEmpty && viewModel.error == nil {
                    Text("No buses operating at this time")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(theme.textMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                }

                // Services header
                HStack(spacing: 6) {
                    if allServicesEnded {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    } else {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .modifier(PulsingModifier())
                    }
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
                                    withAnimation(.easeOut(duration: 0.2)) { favouritesManager.toggleFavourite(arrival.serviceNo, stopCode: stop.id) }
                                }
                            )
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .background(theme.border)
                            .padding(.leading, 84)
                    }
                }
                .animation(.snappy, value: viewModel.arrivals)
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
        .onReceive(refreshTimer) { _ in
            Task { await viewModel.loadArrivals(service: busService) }
        }
    }
}
