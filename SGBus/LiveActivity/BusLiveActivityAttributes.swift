import ActivityKit
import Foundation

struct BusLiveActivityAttributes: ActivityAttributes {
    let serviceNo: String
    let destination: String
    let stopName: String

    struct ContentState: Codable, Hashable {
        let nextBusMinutes: Int?
        let nextBus2Minutes: Int?
        let nextBus3Minutes: Int?
        let nextBusArrivalDate: Date?
    }
}
