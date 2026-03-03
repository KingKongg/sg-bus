import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var favouriteArrivals: [BusArrival] = []
    @Published var isLoading = false

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date.now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    func loadFavourites(service: BusServiceProtocol, favourites: [String]) async {
        isLoading = true
        defer { isLoading = false }

        var arrivals: [BusArrival] = []
        for fav in favourites {
            // Get arrivals from all stops for this service
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
