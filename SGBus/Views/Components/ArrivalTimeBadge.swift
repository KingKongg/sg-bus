import SwiftUI

struct ArrivalTimeBadge: View {
    let arrivalTime: ArrivalTime
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        Text(arrivalTime.displayText)
            .font(.system(.body, design: .monospaced).monospacedDigit())
            .fontWeight(.semibold)
            .foregroundColor(badgeColor)
            .frame(minWidth: 36)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel(accessibilityText)
    }

    private var badgeColor: Color {
        if arrivalTime.isArriving { return theme.arriving }
        if arrivalTime.isSoon { return theme.soon }
        return theme.normal
    }

    private var accessibilityText: String {
        if arrivalTime.isArriving { return "Arriving now" }
        guard let min = arrivalTime.minutesAway else { return "No arrival data" }
        return "\(min) minutes away"
    }
}
