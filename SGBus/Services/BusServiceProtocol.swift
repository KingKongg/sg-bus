import SwiftUI

protocol BusServiceProtocol {
    func getNearbyStops(latitude: Double, longitude: Double, radius: Double) async -> [BusStop]
    func getArrivals(forStop stopCode: String) async throws -> [BusArrival]
    func searchBusStops(query: String) async -> [BusStop]
    func searchBusServices(query: String) async -> [BusServiceModel]
    func getBusServiceDetail(serviceNo: String) async -> BusServiceModel?
    func loadStaticData() async throws
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
