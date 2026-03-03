import Foundation

struct BusArrival: Identifiable, Equatable {
    var id: String { serviceNo }
    let serviceNo: String
    let destination: String
    let nextBus: ArrivalTime
    let nextBus2: ArrivalTime
    let nextBus3: ArrivalTime
    let busType: BusType
    let crowdLevel: CrowdLevel

    static func == (lhs: BusArrival, rhs: BusArrival) -> Bool {
        lhs.serviceNo == rhs.serviceNo &&
        lhs.destination == rhs.destination &&
        lhs.nextBus.displayText == rhs.nextBus.displayText &&
        lhs.nextBus2.displayText == rhs.nextBus2.displayText &&
        lhs.nextBus3.displayText == rhs.nextBus3.displayText &&
        lhs.busType == rhs.busType &&
        lhs.crowdLevel == rhs.crowdLevel
    }
}
