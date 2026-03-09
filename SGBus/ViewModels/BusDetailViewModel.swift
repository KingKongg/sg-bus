import SwiftUI

@MainActor
final class BusDetailViewModel: ObservableObject {
    @Published var serviceDetail: BusServiceModel?
    @Published var arrival: BusArrival?
    @Published var isLoading = false
    @Published var error: String?

    let serviceNo: String

    init(serviceNo: String) {
        self.serviceNo = serviceNo
    }

    func refreshArrivals(service: BusServiceProtocol) async {
        guard let firstStop = serviceDetail?.routeStops.first else { return }
        do {
            let arrivals = try await service.getArrivals(forStop: firstStop.id)
            arrival = arrivals.first { $0.serviceNo == serviceNo }
        } catch is CancellationError { }
        catch let urlError as URLError where urlError.code == .cancelled { }
        catch { self.error = error.localizedDescription }
    }

    func load(service: BusServiceProtocol) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        serviceDetail = await service.getBusServiceDetail(serviceNo: serviceNo)

        if let firstStop = serviceDetail?.routeStops.first {
            do {
                let arrivals = try await service.getArrivals(forStop: firstStop.id)
                arrival = arrivals.first { $0.serviceNo == serviceNo }
            } catch is CancellationError {
                // Ignore — happens naturally during pull-to-refresh
            } catch let urlError as URLError where urlError.code == .cancelled {
                // Ignore — URLSession cancelled during pull-to-refresh
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
