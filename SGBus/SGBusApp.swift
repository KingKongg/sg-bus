import ActivityKit
import SwiftUI

@main
struct SGBusApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var favouritesManager = FavouritesManager()
    @StateObject private var pinManager = PinManager()
    @State private var selectedTab = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                SearchView()
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(1)

                MeView()
                    .tabItem {
                        Label("Me", systemImage: "person.fill")
                    }
                    .tag(2)
            }
            .environmentObject(theme)
            .environmentObject(favouritesManager)
            .environmentObject(pinManager)
            .environment(\.busService, MockBusService())
            .preferredColorScheme(theme.colorScheme)
            .tint(theme.accent)
            .font(.system(.body, design: .monospaced))
            .task {
                pinManager.cleanupOrphanedActivities()
            }
        }
    }
}
