import XCTest
@testable import SGBus

final class FavouritesManagerTests: XCTestCase {

    private var manager: FavouritesManager!
    private let testSuite = "FavouritesManagerTests"

    override func setUp() {
        super.setUp()
        // Clear any existing data
        UserDefaults.standard.removeObject(forKey: "sg_bus_favourites_v2")
        UserDefaults.standard.removeObject(forKey: "sg_bus_favourites")
        UserDefaults.standard.removeObject(forKey: "sg_bus_recents")
        manager = FavouritesManager()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "sg_bus_favourites_v2")
        UserDefaults.standard.removeObject(forKey: "sg_bus_favourites")
        UserDefaults.standard.removeObject(forKey: "sg_bus_recents")
        super.tearDown()
    }

    func testToggleFavouriteWithStopCode() {
        manager.toggleFavourite("10", stopCode: "01012")
        XCTAssertTrue(manager.isFavourite(serviceNo: "10", stopCode: "01012"))
        XCTAssertTrue(manager.isFavourite("10"))
        XCTAssertEqual(manager.favouriteBuses.count, 1)
        XCTAssertEqual(manager.favouriteBuses[0].stopCode, "01012")

        // Toggle off
        manager.toggleFavourite("10", stopCode: "01012")
        XCTAssertFalse(manager.isFavourite("10"))
        XCTAssertEqual(manager.favouriteBuses.count, 0)
    }

    func testToggleFavouriteWithoutStopCode() {
        manager.toggleFavourite("10")
        XCTAssertTrue(manager.isFavourite("10"))
        XCTAssertEqual(manager.favouriteBuses[0].stopCode, "")
    }

    func testFavouriteId() {
        let fav = FavouriteBus(serviceNo: "10", stopCode: "01012")
        XCTAssertEqual(fav.id, "10_01012")
    }

    func testLegacyMigration() {
        // Simulate legacy format
        UserDefaults.standard.set(["10", "15", "33"], forKey: "sg_bus_favourites")
        let migrated = FavouritesManager()
        XCTAssertEqual(migrated.favouriteBuses.count, 3)
        XCTAssertEqual(migrated.favouriteBuses[0].serviceNo, "10")
        XCTAssertEqual(migrated.favouriteBuses[0].stopCode, "")
    }

    func testPersistence() {
        manager.toggleFavourite("10", stopCode: "01012")
        let reloaded = FavouritesManager()
        XCTAssertEqual(reloaded.favouriteBuses.count, 1)
        XCTAssertEqual(reloaded.favouriteBuses[0].serviceNo, "10")
        XCTAssertEqual(reloaded.favouriteBuses[0].stopCode, "01012")
    }

    func testRecentSearches() {
        manager.addRecentSearch(RecentSearch(type: .bus, query: "10", displayName: "Bus 10"))
        XCTAssertEqual(manager.recentSearches.count, 1)

        // Adding same query replaces
        manager.addRecentSearch(RecentSearch(type: .bus, query: "10", displayName: "Bus 10"))
        XCTAssertEqual(manager.recentSearches.count, 1)

        manager.clearRecents()
        XCTAssertTrue(manager.recentSearches.isEmpty)
    }
}
