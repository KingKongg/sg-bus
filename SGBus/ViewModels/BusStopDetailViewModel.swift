import SwiftUI

@MainActor
final class BusStopDetailViewModel: ObservableObject {
    @Published var arrivals: [BusArrival] = []
    @Published var isLoading = false

    let stop: BusStop

    init(stop: BusStop) {
        self.stop = stop
    }

    func loadArrivals(service: BusServiceProtocol) async {
        isLoading = true
        defer { isLoading = false }
        arrivals = await service.getArrivals(forStop: stop.id)
    }
}
