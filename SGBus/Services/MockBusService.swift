import Foundation

final class MockBusService: BusServiceProtocol {

    // MARK: - Mock Data

    static let stops: [BusStop] = [
        BusStop(id: "01012", name: "Hotel Grand Pacific", road: "Victoria St", distanceMetres: 120, busServices: ["36", "56", "111", "175"]),
        BusStop(id: "01013", name: "St. Joseph's Ch", road: "Victoria St", distanceMetres: 250, busServices: ["36", "56", "111"]),
        BusStop(id: "01112", name: "Raffles Hotel", road: "Beach Rd", distanceMetres: 380, busServices: ["100", "107", "961"]),
        BusStop(id: "03218", name: "Orchard Stn Exit B", road: "Orchard Rd", distanceMetres: nil, busServices: ["36", "77", "106", "110", "111", "123"]),
        BusStop(id: "04167", name: "Botanic Gardens MRT", road: "Bukit Timah Rd", distanceMetres: nil, busServices: ["48", "66", "67", "170", "171"]),
        BusStop(id: "11401", name: "Toa Payoh Int", road: "Toa Payoh Lor 6", distanceMetres: nil, busServices: ["28", "43", "56", "62", "73", "83", "142", "159"]),
        BusStop(id: "17009", name: "Clementi Int", road: "Commonwealth Ave W", distanceMetres: nil, busServices: ["52", "78", "96", "165", "175", "285"]),
        BusStop(id: "22009", name: "Boon Lay Int", road: "Boon Lay Way", distanceMetres: nil, busServices: ["30", "79", "154", "157", "172", "180", "199"]),
        BusStop(id: "46009", name: "Bedok Int", road: "New Upper Changi Rd", distanceMetres: nil, busServices: ["7", "9", "14", "16", "17", "25", "38", "43", "48", "119"]),
        BusStop(id: "75009", name: "Hougang Central Int", road: "Hougang Ave 3", distanceMetres: nil, busServices: ["43", "62", "86", "103", "109", "110", "119"]),
    ]

    static let services: [BusServiceModel] = {
        let allStops = MockBusService.stops
        func stopsFor(_ ids: [String]) -> [BusStop] {
            ids.compactMap { id in allStops.first { $0.id == id } }
        }
        return [
            BusServiceModel(id: "36", origin: "Changi Airport", destination: "Tomlinson Rd", busType: .doubleDeck, routeStops: stopsFor(["01012", "01013", "03218"])),
            BusServiceModel(id: "43", origin: "Punggol Int", destination: "Bedok Int", busType: .singleDeck, routeStops: stopsFor(["75009", "11401", "46009"])),
            BusServiceModel(id: "56", origin: "Bishan Int", destination: "Marina Centre", busType: .doubleDeck, routeStops: stopsFor(["11401", "01012", "01013"])),
            BusServiceModel(id: "62", origin: "Punggol Int", destination: "Sims Place", busType: .singleDeck, routeStops: stopsFor(["75009", "11401"])),
            BusServiceModel(id: "77", origin: "Bukit Timah", destination: "Marina Centre", busType: .singleDeck, routeStops: stopsFor(["03218"])),
            BusServiceModel(id: "83", origin: "Toa Payoh", destination: "Shenton Way", busType: .doubleDeck, routeStops: stopsFor(["11401"])),
            BusServiceModel(id: "86", origin: "Sengkang Int", destination: "Ang Mo Kio", busType: .singleDeck, routeStops: stopsFor(["75009"])),
            BusServiceModel(id: "103", origin: "Yishun Int", destination: "Serangoon", busType: .doubleDeck, routeStops: stopsFor(["75009"])),
            BusServiceModel(id: "106", origin: "Bukit Batok", destination: "Shenton Way", busType: .bendy, routeStops: stopsFor(["03218"])),
            BusServiceModel(id: "110", origin: "Hougang Central", destination: "Changi Airport", busType: .doubleDeck, routeStops: stopsFor(["75009", "46009", "03218"])),
            BusServiceModel(id: "111", origin: "Ghim Moh", destination: "Changi Airport", busType: .doubleDeck, routeStops: stopsFor(["03218", "01012", "01013"])),
            BusServiceModel(id: "119", origin: "Hougang Central", destination: "Bedok Int", busType: .singleDeck, routeStops: stopsFor(["75009", "46009"])),
            BusServiceModel(id: "123", origin: "Bukit Merah", destination: "Sentosa", busType: .bendy, routeStops: stopsFor(["03218"])),
            BusServiceModel(id: "142", origin: "Toa Payoh Int", destination: "Jurong East", busType: .singleDeck, routeStops: stopsFor(["11401"])),
            BusServiceModel(id: "154", origin: "Boon Lay", destination: "Toa Payoh", busType: .doubleDeck, routeStops: stopsFor(["22009"])),
            BusServiceModel(id: "165", origin: "Clementi", destination: "Pasir Ris", busType: .singleDeck, routeStops: stopsFor(["17009"])),
            BusServiceModel(id: "175", origin: "Clementi", destination: "Victoria St", busType: .doubleDeck, routeStops: stopsFor(["17009", "01012"])),
            BusServiceModel(id: "199", origin: "Boon Lay", destination: "Changi Village", busType: .bendy, routeStops: stopsFor(["22009"])),
        ]
    }()

    // MARK: - Arrival Generation

    private func makeArrival(serviceNo: String, destination: String, busType: BusType, crowdLevel: CrowdLevel) -> BusArrival {
        let jitter1 = Double.random(in: 0...3)
        let offset1 = Double(Int.random(in: 1...5)) + jitter1
        let offset2 = offset1 + Double(Int.random(in: 5...12))
        let offset3 = offset2 + Double(Int.random(in: 8...18))

        return BusArrival(
            serviceNo: serviceNo,
            destination: destination,
            nextBus: ArrivalTime(estimatedArrival: Date.now.addingTimeInterval(offset1 * 60)),
            nextBus2: ArrivalTime(estimatedArrival: Date.now.addingTimeInterval(offset2 * 60)),
            nextBus3: ArrivalTime(estimatedArrival: Date.now.addingTimeInterval(offset3 * 60)),
            busType: busType,
            crowdLevel: CrowdLevel.allCases.randomElement()!
        )
    }

    private func crowdFor(_ serviceNo: String) -> CrowdLevel {
        CrowdLevel.allCases.randomElement()!
    }

    // MARK: - Protocol

    func getNearbyStops() async -> [BusStop] {
        Array(Self.stops.prefix(5))
    }

    func getArrivals(forStop stopCode: String) async -> [BusArrival] {
        guard let stop = Self.stops.first(where: { $0.id == stopCode }) else { return [] }
        return stop.busServices.compactMap { serviceNo in
            guard let service = Self.services.first(where: { $0.id == serviceNo }) else { return nil }
            return makeArrival(serviceNo: serviceNo, destination: service.destination, busType: service.busType, crowdLevel: crowdFor(serviceNo))
        }
    }

    func searchBusStops(query: String) async -> [BusStop] {
        let q = query.lowercased()
        return Self.stops.filter {
            $0.id.contains(q) || $0.name.lowercased().contains(q) || $0.road.lowercased().contains(q)
        }
    }

    func searchBusServices(query: String) async -> [BusServiceModel] {
        let q = query.lowercased()
        return Self.services.filter {
            $0.id.lowercased().contains(q) || $0.destination.lowercased().contains(q) || $0.origin.lowercased().contains(q)
        }
    }

    func getBusServiceDetail(serviceNo: String) async -> BusServiceModel? {
        Self.services.first { $0.id == serviceNo }
    }
}
