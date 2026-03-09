import Foundation

// MARK: - Generic wrapper

struct LTAResponse<T: Decodable>: Decodable {
    let value: [T]

    enum CodingKeys: String, CodingKey {
        case value
    }
}

// MARK: - Bus Arrival

struct LTABusArrivalResponse: Decodable {
    let busStopCode: String
    let services: [LTABusArrivalService]

    enum CodingKeys: String, CodingKey {
        case busStopCode = "BusStopCode"
        case services = "Services"
    }
}

struct LTABusArrivalService: Decodable {
    let serviceNo: String
    let operatorId: String?
    let originCode: String?
    let destinationCode: String?
    let nextBus: LTANextBus
    let nextBus2: LTANextBus
    let nextBus3: LTANextBus

    enum CodingKeys: String, CodingKey {
        case serviceNo = "ServiceNo"
        case operatorId = "Operator"
        case originCode = "OriginCode"
        case destinationCode = "DestinationCode"
        case nextBus = "NextBus"
        case nextBus2 = "NextBus2"
        case nextBus3 = "NextBus3"
    }
}

struct LTANextBus: Decodable {
    let estimatedArrival: String
    let load: String
    let type: String
    let originCode: String
    let destinationCode: String
    let feature: String?
    let monitored: Int?

    enum CodingKeys: String, CodingKey {
        case estimatedArrival = "EstimatedArrival"
        case load = "Load"
        case type = "Type"
        case originCode = "OriginCode"
        case destinationCode = "DestinationCode"
        case feature = "Feature"
        case monitored = "Monitored"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        estimatedArrival = (try? container.decode(String.self, forKey: .estimatedArrival)) ?? ""
        load = (try? container.decode(String.self, forKey: .load)) ?? ""
        type = (try? container.decode(String.self, forKey: .type)) ?? ""
        originCode = (try? container.decode(String.self, forKey: .originCode)) ?? ""
        destinationCode = (try? container.decode(String.self, forKey: .destinationCode)) ?? ""
        feature = try? container.decode(String.self, forKey: .feature)
        monitored = try? container.decode(Int.self, forKey: .monitored)
    }
}

// MARK: - Bus Stop

struct LTABusStop: Codable {
    let busStopCode: String
    let roadName: String
    let description: String
    let latitude: Double
    let longitude: Double

    enum CodingKeys: String, CodingKey {
        case busStopCode = "BusStopCode"
        case roadName = "RoadName"
        case description = "Description"
        case latitude = "Latitude"
        case longitude = "Longitude"
    }
}

// MARK: - Bus Route

struct LTABusRoute: Codable {
    let serviceNo: String
    let direction: Int
    let stopSequence: Int
    let busStopCode: String
    let distance: Double

    enum CodingKeys: String, CodingKey {
        case serviceNo = "ServiceNo"
        case direction = "Direction"
        case stopSequence = "StopSequence"
        case busStopCode = "BusStopCode"
        case distance = "Distance"
    }
}

// MARK: - Bus Service Info

struct LTABusServiceInfo: Codable {
    let serviceNo: String
    let direction: Int
    let originCode: String
    let destinationCode: String

    enum CodingKeys: String, CodingKey {
        case serviceNo = "ServiceNo"
        case direction = "Direction"
        case originCode = "OriginCode"
        case destinationCode = "DestinationCode"
    }
}
