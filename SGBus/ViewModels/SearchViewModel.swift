import SwiftUI
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var busStopResults: [BusStop] = []
    @Published var busServiceResults: [BusServiceModel] = []
    @Published var isSearching = false

    private var searchTask: Task<Void, Never>?

    func search(service: BusServiceProtocol) {
        searchTask?.cancel()
        let q = query.trimmingCharacters(in: .whitespaces)

        guard !q.isEmpty else {
            busStopResults = []
            busServiceResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            async let stops = service.searchBusStops(query: q)
            async let services = service.searchBusServices(query: q)

            let (s, svc) = await (stops, services)
            guard !Task.isCancelled else { return }

            busStopResults = s
            busServiceResults = svc
            isSearching = false
        }
    }

    var hasResults: Bool {
        !busStopResults.isEmpty || !busServiceResults.isEmpty
    }

    var popularStops: [BusStop] {
        Array(MockBusService.stops.prefix(5))
    }
}
