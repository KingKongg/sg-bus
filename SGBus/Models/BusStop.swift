import Foundation

struct BusStop: Identifiable, Hashable {
    let id: String // Bus stop code e.g. "01012"
    let name: String
    let road: String
    let distanceMetres: Int?
    let busServices: [String] // Bus service numbers
    var latitude: Double?
    var longitude: Double?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: BusStop, rhs: BusStop) -> Bool {
        lhs.id == rhs.id
    }
}
