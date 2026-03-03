import SwiftUI

struct SavedView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var favouritesManager: FavouritesManager
    @Environment(\.busService) private var busService
    @StateObject private var viewModel = SavedViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if favouritesManager.favouriteBuses.isEmpty {
                    EmptyStateView(
                        icon: "bookmark",
                        title: "No saved buses",
                        subtitle: "Star your favourite bus services to see them here"
                    )
                } else {
                    List {
                        ForEach(viewModel.favouriteArrivals) { arrival in
                            NavigationLink {
                                BusDetailView(serviceNo: arrival.serviceNo)
                            } label: {
                                BusArrivalCard(
                                    arrival: arrival,
                                    isFavourite: true,
                                    onToggleFavourite: {
                                        withAnimation { favouritesManager.toggleFavourite(arrival.serviceNo) }
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation { favouritesManager.toggleFavourite(arrival.serviceNo) }
                                } label: {
                                    Label("Unfavourite", systemImage: "star.slash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(theme.background)
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
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
}
