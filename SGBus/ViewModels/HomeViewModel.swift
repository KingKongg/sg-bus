import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var favouriteArrivals: [(fav: FavouriteBus, arrival: BusArrival?)] = []
    @Published var isLoading = false
    @Published var error: String?

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date.now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    func loadFavourites(service: BusServiceProtocol, favourites: [FavouriteBus]) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        var results: [(fav: FavouriteBus, arrival: BusArrival?)] = []

        for fav in favourites {
            var stopCode = fav.stopCode
            if stopCode.isEmpty {
                if let detail = await service.getBusServiceDetail(serviceNo: fav.serviceNo),
                   let firstStop = detail.routeStops.first {
                    stopCode = firstStop.id
                } else {
                    results.append((fav: fav, arrival: nil))
                    continue
                }
            }
            do {
                let arrivals = try await service.getArrivals(forStop: stopCode)
                let match = arrivals.first { $0.serviceNo == fav.serviceNo }
                results.append((fav: fav, arrival: match))
            } catch is CancellationError {
                return // Keep existing data visible
            } catch let urlError as URLError where urlError.code == .cancelled {
                return // Keep existing data visible
            } catch {
                results.append((fav: fav, arrival: nil))
                self.error = error.localizedDescription
            }
        }

        favouriteArrivals = results
    }
}
