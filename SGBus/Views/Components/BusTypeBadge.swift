import SwiftUI

struct BusTypeBadge: View {
    let busType: BusType

    var body: some View {
        Text(busType.shortName)
            .font(.system(.caption2, design: .monospaced))
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(busType.color)
            .clipShape(Capsule())
            .accessibilityLabel(busType.displayName)
    }
}
