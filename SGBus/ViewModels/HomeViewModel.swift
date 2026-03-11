import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var pinnedArrival: (fav: FavouriteBus, arrival: BusArrival?)?
    @Published var unpinnedFavouriteArrivals: [(fav: FavouriteBus, arrival: BusArrival?)] = []
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

    func loadFavourites(service: BusServiceProtocol, favourites: [FavouriteBus], pinnedServiceNo: String?, pinnedStopCode: String?) async {
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

        // Partition: separate pinned bus from the rest
        if let pinnedServiceNo {
            if let favMatch = results.first(where: { $0.fav.serviceNo == pinnedServiceNo }) {
                // Pinned bus is a favourite — pull it out
                pinnedArrival = favMatch
                unpinnedFavouriteArrivals = results.filter { $0.fav.serviceNo != pinnedServiceNo }
            } else {
                // Pinned bus is NOT a favourite — fetch its data separately
                unpinnedFavouriteArrivals = results
                pinnedArrival = await fetchPinnedArrival(service: service, serviceNo: pinnedServiceNo, stopCode: pinnedStopCode)
            }
        } else {
            pinnedArrival = nil
            unpinnedFavouriteArrivals = results
        }
    }

    private func fetchPinnedArrival(service: BusServiceProtocol, serviceNo: String, stopCode: String?) async -> (fav: FavouriteBus, arrival: BusArrival?)? {
        let resolvedStopCode: String
        if let stopCode, !stopCode.isEmpty {
            resolvedStopCode = stopCode
        } else if let detail = await service.getBusServiceDetail(serviceNo: serviceNo),
                  let firstStop = detail.routeStops.first {
            resolvedStopCode = firstStop.id
        } else {
            return (fav: FavouriteBus(serviceNo: serviceNo, stopCode: ""), arrival: nil)
        }

        do {
            let arrivals = try await service.getArrivals(forStop: resolvedStopCode)
            let match = arrivals.first { $0.serviceNo == serviceNo }
            return (fav: FavouriteBus(serviceNo: serviceNo, stopCode: resolvedStopCode), arrival: match)
        } catch {
            return (fav: FavouriteBus(serviceNo: serviceNo, stopCode: resolvedStopCode), arrival: nil)
        }
    }
}
