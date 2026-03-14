import XCTest
@testable import SGBus

final class LocationManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clean up UserDefaults between tests
        UserDefaults.standard.removeObject(forKey: "LocationManager.lastLatitude")
        UserDefaults.standard.removeObject(forKey: "LocationManager.lastLongitude")
    }

    func testDefaultFallbackReturnsSingapore() {
        let manager = LocationManager()
        XCTAssertNil(manager.currentLocation)
        let effective = manager.effectiveLocation
        XCTAssertEqual(effective.latitude, 1.3521, accuracy: 0.0001)
        XCTAssertEqual(effective.longitude, 103.8198, accuracy: 0.0001)
    }

    func testHasRealLocationFalseByDefault() {
        let manager = LocationManager()
        XCTAssertFalse(manager.hasRealLocation)
    }

    func testLastKnownLocationPersistence() {
        // Simulate saving a location via UserDefaults
        let testLat = 1.3000
        let testLng = 103.8500
        UserDefaults.standard.set(testLat, forKey: "LocationManager.lastLatitude")
        UserDefaults.standard.set(testLng, forKey: "LocationManager.lastLongitude")

        let manager = LocationManager()
        XCTAssertNotNil(manager.currentLocation)
        XCTAssertEqual(manager.currentLocation?.latitude ?? 0, testLat, accuracy: 0.0001)
        XCTAssertEqual(manager.currentLocation?.longitude ?? 0, testLng, accuracy: 0.0001)
        XCTAssertTrue(manager.hasRealLocation)
    }

    func testEffectiveLocationUsesPersistedLocation() {
        let testLat = 1.2900
        let testLng = 103.8000
        UserDefaults.standard.set(testLat, forKey: "LocationManager.lastLatitude")
        UserDefaults.standard.set(testLng, forKey: "LocationManager.lastLongitude")

        let manager = LocationManager()
        let effective = manager.effectiveLocation
        XCTAssertEqual(effective.latitude, testLat, accuracy: 0.0001)
        XCTAssertEqual(effective.longitude, testLng, accuracy: 0.0001)
    }
}
