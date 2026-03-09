import Foundation

final class LTAClient {
    private let baseURL = "https://datamall2.mytransport.sg/ltaodataservice"
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String, sessionConfiguration: URLSessionConfiguration? = nil) {
        self.apiKey = apiKey
        let config = sessionConfiguration ?? {
            let c = URLSessionConfiguration.default
            c.timeoutIntervalForRequest = 10
            return c
        }()
        self.session = URLSession(configuration: config)
    }

    // MARK: - Real-time

    func fetchBusArrivals(stopCode: String, serviceNo: String? = nil) async throws -> LTABusArrivalResponse {
        var urlString = "\(baseURL)/v3/BusArrival?BusStopCode=\(stopCode)"
        if let serviceNo {
            urlString += "&ServiceNo=\(serviceNo)"
        }
        return try await fetch(url: urlString)
    }

    // MARK: - Static (paginated)

    func fetchAllBusStops() async throws -> [LTABusStop] {
        try await fetchAllPages(endpoint: "/BusStops")
    }

    func fetchAllBusRoutes() async throws -> [LTABusRoute] {
        try await fetchAllPages(endpoint: "/BusRoutes")
    }

    func fetchAllBusServices() async throws -> [LTABusServiceInfo] {
        try await fetchAllPages(endpoint: "/BusServices")
    }

    // MARK: - Helpers

    private func fetch<T: Decodable>(url urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw LTAError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "AccountKey")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw LTAError.httpError(statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LTAError.decodingError(String(describing: error))
        }
    }

    private func fetchAllPages<T: Decodable>(endpoint: String) async throws -> [T] {
        var all: [T] = []
        var skip = 0
        while true {
            let urlString = "\(baseURL)\(endpoint)?$skip=\(skip)"
            let response: LTAResponse<T> = try await fetch(url: urlString)
            if response.value.isEmpty { break }
            all.append(contentsOf: response.value)
            skip += 500
        }
        return all
    }
}

enum LTAError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .httpError(let code): return "Server error (\(code))"
        case .decodingError(let detail): return "Decoding error: \(detail)"
        }
    }
}
