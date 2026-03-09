import ActivityKit
import Foundation

struct BusLiveActivityAttributes: ActivityAttributes {
    let serviceNo: String
    let destination: String
    let stopName: String

    struct ContentState: Codable, Hashable {
        let nextBusArrival: Date?
        let nextBus2Arrival: Date?
        let nextBus3Arrival: Date?

        var isOperating: Bool {
            nextBusArrival != nil || nextBus2Arrival != nil || nextBus3Arrival != nil
        }
    }
}
