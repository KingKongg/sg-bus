import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var favouritesManager: FavouritesManager
    @EnvironmentObject private var pinManager: PinManager
    @Environment(\.busService) private var busService
    @StateObject private var viewModel = HomeViewModel()
    @Binding var selectedTab: Int
    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Error banner
                    if let error = viewModel.error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text(error)
                            Spacer()
                            Button("Retry") {
                                Task {
                                    await loadData()
                                }
                            }
                        }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Tracking (pinned bus)
                    if viewModel.pinnedArrival != nil {
                        trackingSection
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Favourites
                    if !favouritesManager.favouriteBuses.isEmpty {
                        favouritesSection
                    } else if viewModel.pinnedArrival == nil {
                        EmptyStateView(
                            icon: "star",
                            title: "No favourites yet",
                            subtitle: "Star a bus service to see it here"
                        )
                        .frame(height: 300)
                    }
                }
                .padding(.horizontal, 16)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: pinManager.pinnedServiceNo)
            }
            .background(theme.background)
            .refreshable {
                await loadData()
            }
        }
        .task {
            await loadData()
        }
        .onReceive(refreshTimer) { _ in
            Task { await loadData() }
        }
        .onChange(of: favouritesManager.favouriteBuses) {
            Task { await loadData() }
        }
        .onChange(of: pinManager.pinnedServiceNo) {
            Task { await loadData() }
        }
    }

    private func loadData() async {
        await viewModel.loadFavourites(
            service: busService,
            favourites: favouritesManager.favouriteBuses,
            pinnedServiceNo: pinManager.pinnedServiceNo,
            pinnedStopCode: pinManager.pinnedStopCode
        )
    }

    private var headerSection: some View {
        EmptyView()
    }

    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(theme.accent)
                    .frame(width: 8, height: 8)
                    .modifier(PulsingModifier())
                Text("Tracking")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(theme.textPrimary)
            }

            if let item = viewModel.pinnedArrival {
                if let arrival = item.arrival {
                    NavigationLink {
                        BusDetailView(serviceNo: arrival.serviceNo)
                    } label: {
                        BusArrivalCard(
                            arrival: arrival,
                            isFavourite: favouritesManager.isFavourite(serviceNo: item.fav.serviceNo, stopCode: item.fav.stopCode),
                            isPinned: true,
                            onToggleFavourite: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    favouritesManager.toggleFavourite(item.fav.serviceNo, stopCode: item.fav.stopCode)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack {
                        Text(item.fav.serviceNo)
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        Text("Not in service")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(theme.textMuted)
                    }
                    .padding(16)
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.accent, lineWidth: 2))
                }
            }
        }
    }

    private var favouritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Only show header if there are unpinned favourites to display
            if !viewModel.unpinnedFavouriteArrivals.isEmpty {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .modifier(PulsingModifier())
                    Text("Favourites")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(theme.textPrimary)
                }
            }

            ForEach(viewModel.unpinnedFavouriteArrivals, id: \.fav.id) { item in
                if let arrival = item.arrival {
                    NavigationLink {
                        BusDetailView(serviceNo: arrival.serviceNo)
                    } label: {
                        BusArrivalCard(
                            arrival: arrival,
                            isFavourite: true,
                            isPinned: false,
                            onToggleFavourite: {
                                withAnimation(.easeOut(duration: 0.2)) { favouritesManager.toggleFavourite(item.fav.serviceNo, stopCode: item.fav.stopCode) }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .offset(y: -20)))
                } else {
                    HStack {
                        Text(item.fav.serviceNo)
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        Text("Not in service")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(theme.textMuted)
                    }
                    .padding(16)
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.border, lineWidth: 1))
                    .transition(.opacity.combined(with: .offset(y: -20)))
                }
            }
        }
    }
}

struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
