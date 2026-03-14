import ActivityKit
import SwiftUI

@main
struct SGBusApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var favouritesManager = FavouritesManager()
    @StateObject private var pinManager = PinManager()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedTab = 0
    @State private var isLoadingStaticData = true
    @State private var loadError: String?
    @Environment(\.scenePhase) private var scenePhase

    private let busService: any BusServiceProtocol = LTABusService(apiKey: APIKeyProvider.ltaAPIKey)

    init() {
        let monoFont = UIFont.monospacedSystemFont(ofSize: 10, weight: .medium)
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.font: monoFont]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.font: monoFont]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                TabView(selection: $selectedTab) {
                    HomeView(selectedTab: $selectedTab)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)

                    NearbyView()
                        .tabItem {
                            Label("Nearby", systemImage: "location.fill")
                        }
                        .tag(1)

                    SearchView()
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(2)

                    MeView()
                        .tabItem {
                            Label("Me", systemImage: "person.fill")
                        }
                        .tag(3)
                }

                if isLoadingStaticData {
                    ZStack {
                        theme.background.ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(theme.accent)
                            Text("Loading bus data...")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(theme.textSecondary)
                            if let loadError {
                                Text(loadError)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .environmentObject(theme)
            .environmentObject(favouritesManager)
            .environmentObject(pinManager)
            .environmentObject(locationManager)
            .environment(\.busService, busService)
            .preferredColorScheme(theme.colorScheme)
            .tint(theme.accent)
            .font(.system(.body, design: .monospaced))
            .task {
                pinManager.registerBackgroundTask()
                pinManager.cleanupOrphanedActivities()
                do {
                    try await busService.loadStaticData()
                } catch {
                    loadError = error.localizedDescription
                }
                isLoadingStaticData = false
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    pinManager.scheduleBackgroundRefresh()
                }
            }
        }
    }
}
