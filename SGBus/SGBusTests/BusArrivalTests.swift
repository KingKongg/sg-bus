import XCTest
@testable import SGBus

final class BusArrivalIsOperatingTests: XCTestCase {

    private func makeArrival(
        nextBus: Date? = nil,
        nextBus2: Date? = nil,
        nextBus3: Date? = nil
    ) -> BusArrival {
        BusArrival(
            serviceNo: "961",
            destination: "Woodlands Int",
            nextBus: ArrivalTime(estimatedArrival: nextBus),
            nextBus2: ArrivalTime(estimatedArrival: nextBus2),
            nextBus3: ArrivalTime(estimatedArrival: nextBus3),
            busType: .singleDeck,
            busOperator: .sbsTransit,
            crowdLevel: .medium,
            isWheelchairAccessible: false
        )
    }

    func testIsOperating_allTimesPresent() {
        let now = Date.now
        let arrival = makeArrival(
            nextBus: now.addingTimeInterval(300),
            nextBus2: now.addingTimeInterval(600),
            nextBus3: now.addingTimeInterval(900)
        )
        XCTAssertTrue(arrival.isOperating)
    }

    func testIsOperating_onlyFirstTimePresent() {
        let arrival = makeArrival(nextBus: Date.now.addingTimeInterval(300))
        XCTAssertTrue(arrival.isOperating)
    }

    func testIsOperating_onlySecondTimePresent() {
        let arrival = makeArrival(nextBus2: Date.now.addingTimeInterval(600))
        XCTAssertTrue(arrival.isOperating)
    }

    func testIsOperating_onlyThirdTimePresent() {
        let arrival = makeArrival(nextBus3: Date.now.addingTimeInterval(900))
        XCTAssertTrue(arrival.isOperating)
    }

    func testIsOperating_noTimesPresent() {
        let arrival = makeArrival()
        XCTAssertFalse(arrival.isOperating)
    }

    func testIsOperating_allTimesNilExplicitly() {
        let arrival = makeArrival(nextBus: nil, nextBus2: nil, nextBus3: nil)
        XCTAssertFalse(arrival.isOperating)
    }
}
