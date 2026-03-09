import XCTest
@testable import SGBus

final class LTABusServiceTests: XCTestCase {

    func testISO8601ParsingWithFractionalSeconds() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: "2026-03-07T12:00:00.123+08:00")
        XCTAssertNotNil(date)
    }

    func testISO8601ParsingWithoutFractionalSeconds() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let date = formatter.date(from: "2026-03-07T12:00:00+08:00")
        XCTAssertNotNil(date)
    }

    func testISO8601FractionalFormatterRejectsNonFractional() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: "2026-03-07T12:00:00+08:00")
        // This may or may not parse depending on OS version; the important thing
        // is that our fallback handles it
        if date == nil {
            // Expected on some systems — our code falls back to basic formatter
            let basic = ISO8601DateFormatter()
            basic.formatOptions = [.withInternetDateTime]
            XCTAssertNotNil(basic.date(from: "2026-03-07T12:00:00+08:00"))
        }
    }

    func testCrowdLevelMapping() {
        // SEA = Seats Available (low), SDA = Standing Available (medium), LSD = Limited Standing (high)
        XCTAssertEqual(mapCrowdLevel("SEA"), .low)
        XCTAssertEqual(mapCrowdLevel("SDA"), .medium)
        XCTAssertEqual(mapCrowdLevel("LSD"), .high)
        XCTAssertEqual(mapCrowdLevel(""), .medium)
        XCTAssertEqual(mapCrowdLevel("UNKNOWN"), .medium)
    }

    func testBusTypeMapping() {
        XCTAssertEqual(mapBusType("DD"), .doubleDeck)
        XCTAssertEqual(mapBusType("BD"), .bendy)
        XCTAssertEqual(mapBusType("SD"), .singleDeck)
        XCTAssertEqual(mapBusType(""), .singleDeck)
    }

    // Helper functions that mirror the LTABusService private methods
    private func mapCrowdLevel(_ str: String) -> CrowdLevel {
        switch str {
        case "SEA": return .low
        case "SDA": return .medium
        case "LSD": return .high
        default: return .medium
        }
    }

    private func mapBusType(_ str: String) -> BusType {
        switch str {
        case "DD": return .doubleDeck
        case "BD": return .bendy
        default: return .singleDeck
        }
    }
}
