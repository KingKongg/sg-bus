import SwiftUI

enum BusType: String, Codable, CaseIterable {
    case singleDeck = "SD"
    case doubleDeck = "DD"
    case bendy = "BD"

    var displayName: String {
        switch self {
        case .singleDeck: "Single Deck"
        case .doubleDeck: "Double Deck"
        case .bendy: "Bendy"
        }
    }

    var shortName: String { displayName }

    var color: Color {
        switch self {
        case .singleDeck: Color(hex: 0x4A4A4A)
        case .doubleDeck: Color(hex: 0x3A5CF5)
        case .bendy: Color(hex: 0x7C4CF5)
        }
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
