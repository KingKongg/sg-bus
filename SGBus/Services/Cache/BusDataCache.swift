import Foundation

actor BusDataCache {
    private let client: LTAClient
    private let cacheDir: URL
    private let staleDays: Int = 7

    // In-memory indices
    private(set) var busStops: [LTABusStop] = []
    private(set) var busRoutes: [LTABusRoute] = []
    private(set) var busServices: [LTABusServiceInfo] = []

    private(set) var stopsByCode: [String: LTABusStop] = [:]
    private(set) var servicesByStop: [String: [String]] = [:]  // stopCode -> [serviceNo]
    private(set) var routesByService: [String: [LTABusRoute]] = [:]  // serviceNo -> routes

    init(client: LTAClient) {
        self.client = client
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.cacheDir = appSupport.appendingPathComponent("SGBusCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func loadOrFetch() async throws {
        if let cached = loadFromDisk(), !cached.isStale {
            busStops = cached.stops
            busRoutes = cached.routes
            busServices = cached.services
        } else {
            async let stops = client.fetchAllBusStops()
            async let routes = client.fetchAllBusRoutes()
            async let services = client.fetchAllBusServices()

            busStops = try await stops
            busRoutes = try await routes
            busServices = try await services

            saveToDisk()
        }
        buildIndices()
    }

    // MARK: - Indices

    private func buildIndices() {
        stopsByCode = Dictionary(uniqueKeysWithValues: busStops.map { ($0.busStopCode, $0) })

        // Build servicesByStop from routes
        var sbs: [String: Set<String>] = [:]
        for route in busRoutes {
            sbs[route.busStopCode, default: []].insert(route.serviceNo)
        }
        servicesByStop = sbs.mapValues { Array($0).sorted() }

        routesByService = Dictionary(grouping: busRoutes, by: \.serviceNo)
    }

    // MARK: - Disk persistence

    private struct CachedData: Codable {
        let stops: [LTABusStop]
        let routes: [LTABusRoute]
        let services: [LTABusServiceInfo]
        let timestamp: Date

        var isStale: Bool {
            Date().timeIntervalSince(timestamp) > Double(7 * 24 * 3600)
        }
    }

    private func loadFromDisk() -> CachedData? {
        let url = cacheDir.appendingPathComponent("static_data.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CachedData.self, from: data)
    }

    private func saveToDisk() {
        let cached = CachedData(stops: busStops, routes: busRoutes, services: busServices, timestamp: Date())
        guard let data = try? JSONEncoder().encode(cached) else { return }
        let url = cacheDir.appendingPathComponent("static_data.json")
        try? data.write(to: url)
    }
}
