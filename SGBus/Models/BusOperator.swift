import SwiftUI

enum BusOperator: String, CaseIterable {
    case sbsTransit = "SBST"
    case smrt = "SMRT"
    case towerTransit = "TTS"
    case goAhead = "GAS"
    case unknown = ""

    init(from operatorId: String?) {
        guard let id = operatorId else {
            self = .unknown
            return
        }
        self = BusOperator(rawValue: id) ?? .unknown
    }

    var shortName: String {
        switch self {
        case .sbsTransit: "SBS"
        case .smrt: "SMRT"
        case .towerTransit: "TTS"
        case .goAhead: "GA"
        case .unknown: ""
        }
    }

    var color: Color {
        switch self {
        case .sbsTransit: Color(hex: 0xC41F85)
        case .smrt: Color(hex: 0xED1C24)
        case .towerTransit: Color(hex: 0x009B3A)
        case .goAhead: Color(hex: 0xF7941D)
        case .unknown: .gray
        }
    }
}
