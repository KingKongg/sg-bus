import Foundation

struct RecentSearch: Codable, Identifiable, Equatable {
    enum SearchType: String, Codable {
        case bus, stop
    }
    let id: UUID
    let type: SearchType
    let query: String
    let displayName: String
    let timestamp: Date

    init(type: SearchType, query: String, displayName: String) {
        self.id = UUID()
        self.type = type
        self.query = query
        self.displayName = displayName
        self.timestamp = Date.now
    }
}

struct FavouriteBus: Codable, Equatable, Identifiable {
    var id: String { "\(serviceNo)_\(stopCode)" }
    let serviceNo: String
    let stopCode: String
}

final class FavouritesManager: ObservableObject {
    @Published var favouriteBuses: [FavouriteBus] {
        didSet { saveFavourites() }
    }
    @Published var recentSearches: [RecentSearch] {
        didSet { saveRecents() }
    }

    private let favouritesKey = "sg_bus_favourites_v2"
    private let legacyFavouritesKey = "sg_bus_favourites"
    private let recentsKey = "sg_bus_recents"

    init() {
        // Try loading v2 format
        if let data = UserDefaults.standard.data(forKey: "sg_bus_favourites_v2"),
           let decoded = try? JSONDecoder().decode([FavouriteBus].self, from: data) {
            self.favouriteBuses = decoded
        } else if let legacy = UserDefaults.standard.stringArray(forKey: "sg_bus_favourites"), !legacy.isEmpty {
            // Migrate: old format was just service numbers, use empty stopCode
            self.favouriteBuses = legacy.map { FavouriteBus(serviceNo: $0, stopCode: "") }
        } else {
            self.favouriteBuses = []
        }

        if let data = UserDefaults.standard.data(forKey: "sg_bus_recents"),
           let decoded = try? JSONDecoder().decode([RecentSearch].self, from: data) {
            self.recentSearches = decoded
        } else {
            self.recentSearches = []
        }
    }

    func isFavourite(_ serviceNo: String) -> Bool {
        favouriteBuses.contains { $0.serviceNo == serviceNo }
    }

    func isFavourite(serviceNo: String, stopCode: String) -> Bool {
        favouriteBuses.contains { $0.serviceNo == serviceNo && $0.stopCode == stopCode }
    }

    func toggleFavourite(_ serviceNo: String, stopCode: String = "") {
        if let index = favouriteBuses.firstIndex(where: { $0.serviceNo == serviceNo && $0.stopCode == stopCode }) {
            favouriteBuses.remove(at: index)
        } else {
            favouriteBuses.append(FavouriteBus(serviceNo: serviceNo, stopCode: stopCode))
        }
    }

    func addRecentSearch(_ search: RecentSearch) {
        recentSearches.removeAll { $0.query == search.query && $0.type == search.type }
        recentSearches.insert(search, at: 0)
        if recentSearches.count > 5 {
            recentSearches = Array(recentSearches.prefix(5))
        }
    }

    func clearRecents() {
        recentSearches = []
    }

    private func saveFavourites() {
        if let data = try? JSONEncoder().encode(favouriteBuses) {
            UserDefaults.standard.set(data, forKey: favouritesKey)
        }
    }

    private func saveRecents() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: recentsKey)
        }
    }
}
