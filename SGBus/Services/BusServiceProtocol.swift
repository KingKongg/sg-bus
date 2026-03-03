import SwiftUI

protocol BusServiceProtocol {
    func getNearbyStops() async -> [BusStop]
    func getArrivals(forStop stopCode: String) async -> [BusArrival]
    func searchBusStops(query: String) async -> [BusStop]
    func searchBusServices(query: String) async -> [BusServiceModel]
    func getBusServiceDetail(serviceNo: String) async -> BusServiceModel?
}

// Environment key for dependency injection
struct BusServiceKey: EnvironmentKey {
    static let defaultValue: any BusServiceProtocol = MockBusService()
}

extension EnvironmentValues {
    var busService: any BusServiceProtocol {
        get { self[BusServiceKey.self] }
        set { self[BusServiceKey.self] = newValue }
    }
}
