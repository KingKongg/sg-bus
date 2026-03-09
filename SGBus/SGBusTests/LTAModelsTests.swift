import XCTest
@testable import SGBus

final class LTAModelsTests: XCTestCase {

    func testDecodeBusArrivalWithAllFields() throws {
        let json = """
        {
            "BusStopCode": "01012",
            "Services": [
                {
                    "ServiceNo": "10",
                    "Operator": "SBST",
                    "OriginCode": "75009",
                    "DestinationCode": "16009",
                    "NextBus": {
                        "OriginCode": "75009",
                        "DestinationCode": "16009",
                        "EstimatedArrival": "2026-03-07T12:00:00+08:00",
                        "Monitored": 1,
                        "Latitude": "1.29",
                        "Longitude": "103.85",
                        "Load": "SEA",
                        "Feature": "WAB",
                        "Type": "DD"
                    },
                    "NextBus2": {
                        "OriginCode": "75009",
                        "DestinationCode": "16009",
                        "EstimatedArrival": "2026-03-07T12:10:00+08:00",
                        "Load": "SDA",
                        "Feature": "",
                        "Type": "SD"
                    },
                    "NextBus3": {
                        "OriginCode": "",
                        "DestinationCode": "",
                        "EstimatedArrival": "",
                        "Load": "",
                        "Feature": "",
                        "Type": ""
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LTABusArrivalResponse.self, from: json)
        XCTAssertEqual(response.busStopCode, "01012")
        XCTAssertEqual(response.services.count, 1)

        let svc = response.services[0]
        XCTAssertEqual(svc.serviceNo, "10")
        XCTAssertEqual(svc.operatorId, "SBST")
        XCTAssertEqual(svc.nextBus.type, "DD")
        XCTAssertEqual(svc.nextBus.load, "SEA")
        XCTAssertEqual(svc.nextBus.feature, "WAB")
        XCTAssertEqual(svc.nextBus3.estimatedArrival, "")
        XCTAssertEqual(svc.nextBus3.type, "")
    }

    func testDecodeNextBusWithMissingFields() throws {
        let json = """
        {
            "OriginCode": "75009",
            "DestinationCode": "16009",
            "EstimatedArrival": "2026-03-07T12:00:00+08:00"
        }
        """.data(using: .utf8)!

        let nextBus = try JSONDecoder().decode(LTANextBus.self, from: json)
        XCTAssertEqual(nextBus.originCode, "75009")
        XCTAssertEqual(nextBus.load, "")
        XCTAssertEqual(nextBus.type, "")
        XCTAssertNil(nextBus.feature)
        XCTAssertNil(nextBus.monitored)
    }

    func testDecodeNextBusEmptyObject() throws {
        let json = "{}".data(using: .utf8)!
        let nextBus = try JSONDecoder().decode(LTANextBus.self, from: json)
        XCTAssertEqual(nextBus.estimatedArrival, "")
        XCTAssertEqual(nextBus.load, "")
        XCTAssertEqual(nextBus.type, "")
        XCTAssertEqual(nextBus.originCode, "")
        XCTAssertEqual(nextBus.destinationCode, "")
    }

    func testDecodeBusArrivalMonitoredField() throws {
        let json = """
        {
            "BusStopCode": "01012",
            "Services": [
                {
                    "ServiceNo": "10",
                    "Operator": "SBST",
                    "OriginCode": "75009",
                    "DestinationCode": "16009",
                    "NextBus": {
                        "OriginCode": "75009",
                        "DestinationCode": "16009",
                        "EstimatedArrival": "2026-03-07T12:00:00+08:00",
                        "Monitored": 1,
                        "Load": "SEA",
                        "Feature": "WAB",
                        "Type": "DD"
                    },
                    "NextBus2": {
                        "OriginCode": "75009",
                        "DestinationCode": "16009",
                        "EstimatedArrival": "2026-03-07T12:10:00+08:00",
                        "Monitored": 0,
                        "Load": "SDA",
                        "Feature": "",
                        "Type": "BD"
                    },
                    "NextBus3": {
                        "OriginCode": "",
                        "DestinationCode": "",
                        "EstimatedArrival": "",
                        "Load": "",
                        "Feature": "",
                        "Type": "SD"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LTABusArrivalResponse.self, from: json)
        let svc = response.services[0]

        // Monitored field
        XCTAssertEqual(svc.nextBus.monitored, 1)
        XCTAssertEqual(svc.nextBus2.monitored, 0)
        XCTAssertNil(svc.nextBus3.monitored)

        // Bus types
        XCTAssertEqual(svc.nextBus.type, "DD")
        XCTAssertEqual(svc.nextBus2.type, "BD")
        XCTAssertEqual(svc.nextBus3.type, "SD")

        // Crowd levels
        XCTAssertEqual(svc.nextBus.load, "SEA")
        XCTAssertEqual(svc.nextBus2.load, "SDA")
    }

    func testDecodeBusArrivalServiceWithoutOperator() throws {
        let json = """
        {
            "ServiceNo": "15",
            "OriginCode": "77009",
            "DestinationCode": "77009",
            "NextBus": {},
            "NextBus2": {},
            "NextBus3": {}
        }
        """.data(using: .utf8)!

        let svc = try JSONDecoder().decode(LTABusArrivalService.self, from: json)
        XCTAssertEqual(svc.serviceNo, "15")
        XCTAssertNil(svc.operatorId)
        XCTAssertEqual(svc.nextBus.estimatedArrival, "")
    }

    func testDecodeBusArrivalServiceWithoutOriginDestination() throws {
        let json = """
        {
            "ServiceNo": "36",
            "Operator": "SBST",
            "NextBus": {
                "OriginCode": "75009",
                "DestinationCode": "16009",
                "EstimatedArrival": "2026-03-07T12:00:00+08:00",
                "Load": "SEA",
                "Type": "DD"
            },
            "NextBus2": {},
            "NextBus3": {}
        }
        """.data(using: .utf8)!

        let svc = try JSONDecoder().decode(LTABusArrivalService.self, from: json)
        XCTAssertEqual(svc.serviceNo, "36")
        XCTAssertNil(svc.originCode)
        XCTAssertNil(svc.destinationCode)
        XCTAssertEqual(svc.nextBus.destinationCode, "16009")
    }
}
