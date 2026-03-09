import SwiftUI

struct BusOperatorBadge: View {
    let busOperator: BusOperator

    var body: some View {
        if busOperator != .unknown {
            Text(busOperator.shortName)
                .font(.system(.caption2, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(busOperator.color)
                .clipShape(Capsule())
                .accessibilityLabel(busOperator.shortName)
        }
    }
}
