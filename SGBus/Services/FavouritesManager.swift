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

final class FavouritesManager: ObservableObject {
    @Published var favouriteBuses: [String] {
        didSet { saveFavourites() }
    }
    @Published var recentSearches: [RecentSearch] {
        didSet { saveRecents() }
    }

    private let favouritesKey = "sg_bus_favourites"
    private let recentsKey = "sg_bus_recents"

    init() {
        self.favouriteBuses = UserDefaults.standard.stringArray(forKey: "sg_bus_favourites") ?? []
        if let data = UserDefaults.standard.data(forKey: "sg_bus_recents"),
           let decoded = try? JSONDecoder().decode([RecentSearch].self, from: data) {
            self.recentSearches = decoded
        } else {
            self.recentSearches = []
        }
    }

    func isFavourite(_ serviceNo: String) -> Bool {
        favouriteBuses.contains(serviceNo)
    }

    func toggleFavourite(_ serviceNo: String) {
        if let index = favouriteBuses.firstIndex(of: serviceNo) {
            favouriteBuses.remove(at: index)
        } else {
            favouriteBuses.append(serviceNo)
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
        UserDefaults.standard.set(favouriteBuses, forKey: favouritesKey)
    }

    private func saveRecents() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: recentsKey)
        }
    }
}
