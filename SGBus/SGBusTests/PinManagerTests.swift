import XCTest
@testable import SGBus

// MARK: - ContentState Date Computation Tests

final class ContentStateDateTests: XCTestCase {

    func testMinutesFromDate_futureDate() {
        let date = Date.now.addingTimeInterval(5 * 60 + 30) // 5.5 min in future
        let minutes = Self.minutesFrom(date)
        XCTAssertEqual(minutes, 5)
    }

    func testMinutesFromDate_pastDate() {
        let date = Date.now.addingTimeInterval(-120) // 2 min in past
        let minutes = Self.minutesFrom(date)
        XCTAssertEqual(minutes, 0, "Past dates should clamp to 0")
    }

    func testMinutesFromDate_nilDate() {
        let minutes = Self.minutesFrom(nil)
        XCTAssertNil(minutes)
    }

    func testMinutesFromDate_arrivingNow() {
        let date = Date.now.addingTimeInterval(30) // 30s away
        let minutes = Self.minutesFrom(date)
        XCTAssertEqual(minutes, 0, "Less than 60s should round to 0")
    }

    // Mirrors the widget helper logic
    private static func minutesFrom(_ date: Date?) -> Int? {
        guard let date else { return nil }
        return max(0, Int(date.timeIntervalSince(Date.now) / 60))
    }
}

// MARK: - ArrivalTime Model Tests

final class ArrivalTimeTests: XCTestCase {

    func testArrivalTimeMinutesAway() {
        // Add 30s buffer so truncation doesn't cause flakiness
        let arrival = ArrivalTime(estimatedArrival: Date.now.addingTimeInterval(5 * 60 + 30))
        XCTAssertEqual(arrival.minutesAway, 5)
    }

    func testArrivalTimeNilDate() {
        let arrival = ArrivalTime(estimatedArrival: nil)
        XCTAssertNil(arrival.minutesAway)
        XCTAssertEqual(arrival.displayText, "-")
    }

    func testArrivalTimeArriving() {
        let arrival = ArrivalTime(estimatedArrival: Date.now.addingTimeInterval(10))
        XCTAssertEqual(arrival.displayText, "Arr")
        XCTAssertTrue(arrival.isArriving)
    }

    func testArrivalTimePastDate() {
        let arrival = ArrivalTime(estimatedArrival: Date.now.addingTimeInterval(-60))
        XCTAssertEqual(arrival.minutesAway, 0)
        XCTAssertEqual(arrival.displayText, "Arr")
    }
}

// MARK: - PinManager State Tests

@MainActor
final class PinManagerStateTests: XCTestCase {

    private var pinManager: PinManager!
    private var mockService: MockBusService!

    override func setUp() {
        super.setUp()
        pinManager = PinManager()
        mockService = MockBusService()
    }

    override func tearDown() {
        pinManager.unpin()
        pinManager = nil
        mockService = nil
        super.tearDown()
    }

    private func makeArrival(serviceNo: String = "175", minutesAway: Double = 5) -> BusArrival {
        BusArrival(
            serviceNo: serviceNo,
            destination: "Victoria St",
            nextBus: ArrivalTime(estimatedArrival: Date.now.addingTimeInterval(minutesAway * 60)),
            nextBus2: ArrivalTime(estimatedArrival: Date.now.addingTimeInterval((minutesAway + 8) * 60)),
            nextBus3: ArrivalTime(estimatedArrival: Date.now.addingTimeInterval((minutesAway + 15) * 60)),
            busType: .doubleDeck,
            busOperator: .sbsTransit,
            crowdLevel: .low,
            isWheelchairAccessible: false
        )
    }

    func testPinSetsState() {
        let arrival = makeArrival()
        pinManager.pin(
            serviceNo: "175",
            destination: "Victoria St",
            stopName: "Hotel Grand Pacific",
            stopCode: "01012",
            busService: mockService,
            initialArrival: arrival
        )

        XCTAssertTrue(pinManager.isPinned("175"))
        XCTAssertEqual(pinManager.pinnedServiceNo, "175")
        XCTAssertEqual(pinManager.pinnedStopCode, "01012")
    }

    func testUnpinClearsState() {
        let arrival = makeArrival()
        pinManager.pin(
            serviceNo: "175",
            destination: "Victoria St",
            stopName: "Hotel Grand Pacific",
            stopCode: "01012",
            busService: mockService,
            initialArrival: arrival
        )

        pinManager.unpin()

        XCTAssertFalse(pinManager.isPinned("175"))
        XCTAssertNil(pinManager.pinnedServiceNo)
        XCTAssertNil(pinManager.pinnedStopCode)
    }

    func testPinReplacesExisting() {
        let arrival1 = makeArrival(serviceNo: "175")
        pinManager.pin(
            serviceNo: "175",
            destination: "Victoria St",
            stopName: "Hotel Grand Pacific",
            stopCode: "01012",
            busService: mockService,
            initialArrival: arrival1
        )

        let arrival2 = makeArrival(serviceNo: "36")
        pinManager.pin(
            serviceNo: "36",
            destination: "Tomlinson Rd",
            stopName: "Hotel Grand Pacific",
            stopCode: "01012",
            busService: mockService,
            initialArrival: arrival2
        )

        XCTAssertFalse(pinManager.isPinned("175"))
        XCTAssertTrue(pinManager.isPinned("36"))
        XCTAssertEqual(pinManager.pinnedServiceNo, "36")
    }

    func testIsPinnedReturnsFalseForDifferentService() {
        let arrival = makeArrival(serviceNo: "175")
        pinManager.pin(
            serviceNo: "175",
            destination: "Victoria St",
            stopName: "Hotel Grand Pacific",
            stopCode: "01012",
            busService: mockService,
            initialArrival: arrival
        )

        XCTAssertFalse(pinManager.isPinned("999"))
        XCTAssertFalse(pinManager.isPinned("36"))
    }
}

// MARK: - Refresh Logic Tests

@MainActor
final class PinManagerRefreshTests: XCTestCase {

    func testRefreshWithNoActivityDoesNotCrash() async {
        let pinManager = PinManager()
        // No pin set — should silently return
        await pinManager.refreshActivity()
    }

    func testRefreshWithAPIErrorDoesNotCrash() async {
        let pinManager = PinManager()
        let errorService = ErrorThrowingBusService()

        let arrival = BusArrival(
            serviceNo: "175",
            destination: "Victoria St",
            nextBus: ArrivalTime(estimatedArrival: Date.now.addingTimeInterval(300)),
            nextBus2: ArrivalTime(estimatedArrival: Date.now.addingTimeInterval(600)),
            nextBus3: ArrivalTime(estimatedArrival: Date.now.addingTimeInterval(900)),
            busType: .doubleDeck,
            busOperator: .sbsTransit,
            crowdLevel: .low,
            isWheelchairAccessible: false
        )

        pinManager.pin(
            serviceNo: "175",
            destination: "Victoria St",
            stopName: "Hotel Grand Pacific",
            stopCode: "01012",
            busService: errorService,
            initialArrival: arrival
        )

        // Should not crash even though service throws
        await pinManager.refreshActivity()

        // State should still be pinned (not cleared on error)
        XCTAssertTrue(pinManager.isPinned("175"))

        pinManager.unpin()
    }
}

// MARK: - Test Helpers

private final class ErrorThrowingBusService: BusServiceProtocol {
    struct ServiceError: Error {}

    func getNearbyStops(latitude: Double, longitude: Double, radius: Double) async -> [BusStop] { [] }
    func loadStaticData() async throws { }
    func getArrivals(forStop stopCode: String) async throws -> [BusArrival] {
        throw ServiceError()
    }
    func searchBusStops(query: String) async -> [BusStop] { [] }
    func searchBusServices(query: String) async -> [BusServiceModel] { [] }
    func getBusServiceDetail(serviceNo: String) async -> BusServiceModel? { nil }
}
