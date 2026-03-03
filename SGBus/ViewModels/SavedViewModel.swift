import SwiftUI

@MainActor
final class SavedViewModel: ObservableObject {
    @Published var favouriteArrivals: [BusArrival] = []
    @Published var isLoading = false

    func loadFavourites(service: BusServiceProtocol, favourites: [String]) async {
        isLoading = true
        defer { isLoading = false }

        var arrivals: [BusArrival] = []
        for fav in favourites {
            let stops = await service.getNearbyStops()
            for stop in stops {
                let stopArrivals = await service.getArrivals(forStop: stop.id)
                if let match = stopArrivals.first(where: { $0.serviceNo == fav }) {
                    arrivals.append(match)
                    break
                }
            }
        }
        favouriteArrivals = arrivals
    }
}
