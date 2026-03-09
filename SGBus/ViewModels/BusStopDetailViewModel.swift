import SwiftUI

@MainActor
final class BusStopDetailViewModel: ObservableObject {
    @Published var arrivals: [BusArrival] = []
    @Published var isLoading = false
    @Published var error: String?

    let stop: BusStop

    init(stop: BusStop) {
        self.stop = stop
    }

    func loadArrivals(service: BusServiceProtocol) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            arrivals = try await service.getArrivals(forStop: stop.id)
        } catch is CancellationError {
            // Ignore — happens naturally during pull-to-refresh
        } catch let urlError as URLError where urlError.code == .cancelled {
            // Ignore — URLSession cancelled during pull-to-refresh
        } catch {
            self.error = error.localizedDescription
        }
    }
}
