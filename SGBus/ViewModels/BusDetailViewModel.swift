import SwiftUI

@MainActor
final class BusDetailViewModel: ObservableObject {
    @Published var serviceDetail: BusServiceModel?
    @Published var arrival: BusArrival?
    @Published var isLoading = false

    let serviceNo: String

    init(serviceNo: String) {
        self.serviceNo = serviceNo
    }

    func load(service: BusServiceProtocol) async {
        isLoading = true
        defer { isLoading = false }

        serviceDetail = await service.getBusServiceDetail(serviceNo: serviceNo)

        // Get arrival from first route stop
        if let firstStop = serviceDetail?.routeStops.first {
            let arrivals = await service.getArrivals(forStop: firstStop.id)
            arrival = arrivals.first { $0.serviceNo == serviceNo }
        }
    }
}
