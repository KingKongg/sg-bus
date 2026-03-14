import Foundation

final class LTABusService: BusServiceProtocol {
    private let client: LTAClient
    private let cache: BusDataCache

    private static let iso8601Fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601Basic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    init(apiKey: String) {
        self.client = LTAClient(apiKey: apiKey)
        self.cache = BusDataCache(client: client)
    }

    func loadStaticData() async throws {
        try await cache.loadOrFetch()
    }

    // MARK: - Protocol

    func getNearbyStops(latitude: Double, longitude: Double, radius: Double) async -> [BusStop] {
        let allStops = await cache.busStops
        let servicesByStop = await cache.servicesByStop

        return allStops.compactMap { ltaStop -> BusStop? in
            let dist = LocationManager.haversineDistance(
                lat1: latitude, lon1: longitude,
                lat2: ltaStop.latitude, lon2: ltaStop.longitude
            )
            guard dist <= radius else { return nil }
            return BusStop(
                id: ltaStop.busStopCode,
                name: ltaStop.description,
                road: ltaStop.roadName,
                distanceMetres: Int(dist),
                busServices: servicesByStop[ltaStop.busStopCode] ?? [],
                latitude: ltaStop.latitude,
                longitude: ltaStop.longitude
            )
        }.sorted { ($0.distanceMetres ?? 0) < ($1.distanceMetres ?? 0) }
    }

    func getArrivals(forStop stopCode: String) async throws -> [BusArrival] {
        let response = try await client.fetchBusArrivals(stopCode: stopCode)
        var arrivals: [BusArrival] = []

        for svc in response.services {
            let destCode = svc.destinationCode ?? svc.nextBus.destinationCode
            let destName = await cache.stopsByCode[destCode]?.description ?? destCode

            let arrival = BusArrival(
                serviceNo: svc.serviceNo,
                destination: destName,
                nextBus: parseArrivalTime(svc.nextBus.estimatedArrival),
                nextBus2: parseArrivalTime(svc.nextBus2.estimatedArrival),
                nextBus3: parseArrivalTime(svc.nextBus3.estimatedArrival),
                busType: parseBusType(svc.nextBus.type),
                busOperator: BusOperator(from: svc.operatorId),
                crowdLevel: parseCrowdLevel(svc.nextBus.load),
                isWheelchairAccessible: svc.nextBus.feature == "WAB"
            )
            arrivals.append(arrival)
        }

        return arrivals
    }

    func searchBusStops(query: String) async -> [BusStop] {
        let q = query.lowercased()
        let stops = await cache.busStops
        let servicesByStop = await cache.servicesByStop

        return stops.compactMap { ltaStop in
            let matches = ltaStop.busStopCode.lowercased().contains(q)
                || ltaStop.description.lowercased().contains(q)
                || ltaStop.roadName.lowercased().contains(q)
            guard matches else { return nil as BusStop? }

            return BusStop(
                id: ltaStop.busStopCode,
                name: ltaStop.description,
                road: ltaStop.roadName,
                distanceMetres: nil,
                busServices: servicesByStop[ltaStop.busStopCode] ?? [],
                latitude: ltaStop.latitude,
                longitude: ltaStop.longitude
            )
        }
    }

    func searchBusServices(query: String) async -> [BusServiceModel] {
        let q = query.lowercased()
        let services = await cache.busServices
        let stopsByCode = await cache.stopsByCode
        let routesByService = await cache.routesByService

        // Group by serviceNo (multiple directions), take direction 1
        let grouped = Dictionary(grouping: services, by: \.serviceNo)

        return grouped.compactMap { (serviceNo, infos) -> BusServiceModel? in
            guard serviceNo.lowercased().contains(q) else { return nil }
            guard let info = infos.first(where: { $0.direction == 1 }) ?? infos.first else { return nil }

            let originName = stopsByCode[info.originCode]?.description ?? info.originCode
            let destName = stopsByCode[info.destinationCode]?.description ?? info.destinationCode

            let routes = (routesByService[serviceNo] ?? [])
                .filter { $0.direction == 1 }
                .sorted { $0.stopSequence < $1.stopSequence }

            let routeStops = routes.compactMap { route -> BusStop? in
                guard let stop = stopsByCode[route.busStopCode] else { return nil }
                return BusStop(
                    id: stop.busStopCode,
                    name: stop.description,
                    road: stop.roadName,
                    distanceMetres: nil,
                    busServices: [],
                    latitude: stop.latitude,
                    longitude: stop.longitude
                )
            }

            return BusServiceModel(
                id: serviceNo,
                origin: originName,
                destination: destName,
                busType: .singleDeck,
                routeStops: routeStops
            )
        }.sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
    }

    func getBusServiceDetail(serviceNo: String) async -> BusServiceModel? {
        let services = await cache.busServices
        let stopsByCode = await cache.stopsByCode
        let routesByService = await cache.routesByService

        guard let info = services.first(where: { $0.serviceNo == serviceNo && $0.direction == 1 })
                ?? services.first(where: { $0.serviceNo == serviceNo }) else { return nil }

        let originName = stopsByCode[info.originCode]?.description ?? info.originCode
        let destName = stopsByCode[info.destinationCode]?.description ?? info.destinationCode

        let routes = (routesByService[serviceNo] ?? [])
            .filter { $0.direction == 1 }
            .sorted { $0.stopSequence < $1.stopSequence }

        let routeStops = routes.compactMap { route -> BusStop? in
            guard let stop = stopsByCode[route.busStopCode] else { return nil }
            return BusStop(
                id: stop.busStopCode,
                name: stop.description,
                road: stop.roadName,
                distanceMetres: nil,
                busServices: [],
                latitude: stop.latitude,
                longitude: stop.longitude
            )
        }

        return BusServiceModel(
            id: serviceNo,
            origin: originName,
            destination: destName,
            busType: .singleDeck,
            routeStops: routeStops
        )
    }

    // MARK: - Parsing

    private func parseArrivalTime(_ str: String) -> ArrivalTime {
        guard !str.isEmpty,
              let date = Self.iso8601Fractional.date(from: str) ?? Self.iso8601Basic.date(from: str) else {
            return ArrivalTime(estimatedArrival: nil)
        }
        return ArrivalTime(estimatedArrival: date)
    }

    private func parseBusType(_ str: String) -> BusType {
        switch str {
        case "DD": return .doubleDeck
        case "BD": return .bendy
        default: return .singleDeck
        }
    }

    private func parseCrowdLevel(_ str: String) -> CrowdLevel {
        switch str {
        case "SEA": return .low
        case "SDA": return .medium
        case "LSD": return .high
        default: return .medium
        }
    }
}
