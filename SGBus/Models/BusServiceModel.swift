import Foundation

struct BusServiceModel: Identifiable {
    let id: String // Bus number e.g. "110"
    let origin: String
    let destination: String
    let busType: BusType
    let routeStops: [BusStop]
}
