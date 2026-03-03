import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var favouritesManager: FavouritesManager
    @Environment(\.busService) private var busService
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.query.isEmpty {
                    // Recent searches
                    if !favouritesManager.recentSearches.isEmpty {
                        Section {
                            ForEach(favouritesManager.recentSearches) { recent in
                                recentSearchRow(recent)
                            }
                        } header: {
                            HStack {
                                Text("Recent")
                                    .font(.system(.caption, design: .monospaced))
                                Spacer()
                                Button("Clear") {
                                    favouritesManager.clearRecents()
                                }
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(theme.accent)
                            }
                        }
                    }

                    // Popular stops
                    Section {
                        ForEach(viewModel.popularStops) { stop in
                            NavigationLink {
                                BusStopDetailView(stop: stop)
                            } label: {
                                stopRow(stop)
                            }
                        }
                    } header: {
                        Text("Popular Stops")
                            .font(.system(.caption, design: .monospaced))
                    }
                } else if viewModel.hasResults {
                    // Bus services results
                    if !viewModel.busServiceResults.isEmpty {
                        Section {
                            ForEach(viewModel.busServiceResults) { svc in
                                NavigationLink {
                                    BusDetailView(serviceNo: svc.id)
                                } label: {
                                    serviceRow(svc)
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    favouritesManager.addRecentSearch(
                                        RecentSearch(type: .bus, query: svc.id, displayName: "Bus \(svc.id)")
                                    )
                                })
                            }
                        } header: {
                            Text("Bus Services")
                                .font(.system(.caption, design: .monospaced))
                        }
                    }

                    // Bus stops results
                    if !viewModel.busStopResults.isEmpty {
                        Section {
                            ForEach(viewModel.busStopResults) { stop in
                                NavigationLink {
                                    BusStopDetailView(stop: stop)
                                } label: {
                                    stopRow(stop)
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    favouritesManager.addRecentSearch(
                                        RecentSearch(type: .stop, query: stop.id, displayName: stop.name)
                                    )
                                })
                            }
                        } header: {
                            Text("Bus Stops")
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                } else if !viewModel.isSearching {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No results",
                        subtitle: "Try a different search term"
                    )
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.query, prompt: "Bus number or stop name")
            .onChange(of: viewModel.query) {
                viewModel.search(service: busService)
            }
        }
    }

    private func recentSearchRow(_ recent: RecentSearch) -> some View {
        NavigationLink {
            if recent.type == .bus {
                BusDetailView(serviceNo: recent.query)
            } else {
                // Navigate to stop search
                BusStopDetailView(stop: MockBusService.stops.first { $0.id == recent.query } ?? BusStop(id: recent.query, name: recent.displayName, road: "", distanceMetres: nil, busServices: []))
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: recent.type == .bus ? "bus.fill" : "mappin.circle.fill")
                    .foregroundColor(theme.accent)
                    .frame(width: 24)
                Text(recent.displayName)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.left")
                    .font(.caption)
                    .foregroundColor(theme.textMuted)
            }
        }
    }

    private func stopRow(_ stop: BusStop) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stop.name)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(theme.textPrimary)
            HStack(spacing: 8) {
                Text(stop.id)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(theme.textMuted)
                Text(stop.road)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(theme.textSecondary)
            }
        }
    }

    private func serviceRow(_ svc: BusServiceModel) -> some View {
        HStack(spacing: 12) {
            Text(svc.id)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
                .frame(minWidth: 48, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(svc.origin) → \(svc.destination)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
                BusTypeBadge(busType: svc.busType)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.textMuted)
        }
    }
}
