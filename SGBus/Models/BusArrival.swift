import Foundation

struct BusArrival: Identifiable {
    let id = UUID()
    let serviceNo: String
    let destination: String
    let nextBus: ArrivalTime
    let nextBus2: ArrivalTime
    let nextBus3: ArrivalTime
    let busType: BusType
    let crowdLevel: CrowdLevel
}
