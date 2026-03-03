import SwiftUI

enum CrowdLevel: String, Codable, CaseIterable {
    case low = "SEA"
    case medium = "SDA"
    case high = "LSD"

    var displayName: String {
        switch self {
        case .low: "Seats Avail"
        case .medium: "Standing"
        case .high: "Crowded"
        }
    }

    var color: Color {
        switch self {
        case .low: Color(hex: 0x2E7D4F)
        case .medium: Color(hex: 0x9A7500)
        case .high: Color(hex: 0xB03030)
        }
    }

    var dotCount: Int {
        switch self {
        case .low: 1
        case .medium: 2
        case .high: 3
        }
    }
}
