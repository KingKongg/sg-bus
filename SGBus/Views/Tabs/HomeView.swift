import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var favouritesManager: FavouritesManager
    @EnvironmentObject private var pinManager: PinManager
    @Environment(\.busService) private var busService
    @StateObject private var viewModel = HomeViewModel()
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Favourites
                    if !favouritesManager.favouriteBuses.isEmpty {
                        favouritesSection
                    } else {
                        EmptyStateView(
                            icon: "star",
                            title: "No favourites yet",
                            subtitle: "Star a bus service to see it here"
                        )
                        .frame(height: 300)
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(theme.background)
            .refreshable {
                await viewModel.loadFavourites(service: busService, favourites: favouritesManager.favouriteBuses)
            }
        }
        .task {
            await viewModel.loadFavourites(service: busService, favourites: favouritesManager.favouriteBuses)
        }
        .onChange(of: favouritesManager.favouriteBuses) {
            Task {
                await viewModel.loadFavourites(service: busService, favourites: favouritesManager.favouriteBuses)
            }
        }
    }

    private var headerSection: some View {
        EmptyView()
    }

    private var favouritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .modifier(PulsingModifier())
                Text("Favourites")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(theme.textPrimary)
            }

            ForEach(viewModel.favouriteArrivals) { arrival in
                NavigationLink {
                    BusDetailView(serviceNo: arrival.serviceNo)
                } label: {
                    BusArrivalCard(
                        arrival: arrival,
                        isFavourite: true,
                        isPinned: pinManager.isPinned(arrival.serviceNo),
                        onToggleFavourite: {
                            withAnimation(.easeOut(duration: 0.2)) { favouritesManager.toggleFavourite(arrival.serviceNo) }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
            .animation(.snappy, value: viewModel.favouriteArrivals)
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
