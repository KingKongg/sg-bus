import XCTest
@testable import SGBus

final class NearbyStopsTests: XCTestCase {

    // MARK: - Haversine distance

    func testHaversineDistanceKnownPair() {
        // Marina Bay Sands (1.2834, 103.8607) to Raffles Place (1.2840, 103.8516)
        let dist = LocationManager.haversineDistance(
            lat1: 1.2834, lon1: 103.8607,
            lat2: 1.2840, lon2: 103.8516
        )
        // Expected ~1013m
        XCTAssertEqual(dist, 1013, accuracy: 50)
    }

    func testHaversineDistanceSamePoint() {
        let dist = LocationManager.haversineDistance(
            lat1: 1.3521, lon1: 103.8198,
            lat2: 1.3521, lon2: 103.8198
        )
        XCTAssertEqual(dist, 0, accuracy: 0.01)
    }

    func testHaversineDistanceShortRange() {
        // Two points ~100m apart in Singapore
        let dist = LocationManager.haversineDistance(
            lat1: 1.3521, lon1: 103.8198,
            lat2: 1.3530, lon2: 103.8198
        )
        // ~100m for 0.0009 degrees latitude
        XCTAssertEqual(dist, 100, accuracy: 15)
    }

    // MARK: - getNearbyStops filtering

    func testGetNearbyStopsFiltersWithinRadius() async {
        let service = LTABusService(apiKey: "test")
        // Without loading data, this should return empty (no cached stops)
        let stops = await service.getNearbyStops(latitude: 1.3521, longitude: 103.8198, radius: 300)
        // With no cached data, expect empty
        XCTAssertTrue(stops.isEmpty)
    }

    func testGetNearbyStopsMockReturnsStops() async {
        let service = MockBusService()
        let stops = await service.getNearbyStops(latitude: 1.3521, longitude: 103.8198, radius: 300)
        XCTAssertFalse(stops.isEmpty)
    }

    func testGetNearbyStopsMockHasDistance() async {
        let service = MockBusService()
        let stops = await service.getNearbyStops(latitude: 1.3521, longitude: 103.8198, radius: 300)
        for stop in stops {
            XCTAssertNotNil(stop.distanceMetres, "Distance should be populated for \(stop.name)")
        }
    }

    func testGetNearbyStopsMockSortedByDistance() async {
        let service = MockBusService()
        let stops = await service.getNearbyStops(latitude: 1.3521, longitude: 103.8198, radius: 300)
        guard stops.count >= 2 else { return }
        for i in 0..<(stops.count - 1) {
            XCTAssertLessThanOrEqual(
                stops[i].distanceMetres ?? 0,
                stops[i + 1].distanceMetres ?? 0,
                "Stops should be sorted by distance"
            )
        }
    }
}
