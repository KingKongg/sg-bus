import SwiftUI

struct BusArrivalCard: View {
    let arrival: BusArrival
    let isFavourite: Bool
    var isPinned: Bool = false
    let onToggleFavourite: () -> Void

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: bus number + arrival time
            HStack(alignment: .top) {
                Text(arrival.serviceNo)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.textPrimary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(primaryArrivalText)
                        .font(.system(size: arrival.isOperating ? 28 : 14, weight: .bold, design: .monospaced))
                        .contentTransition(.numericText())
                        .foregroundColor(primaryArrivalColor)
                        .animation(.snappy(duration: 0.3), value: primaryArrivalText)

                    if arrival.isOperating && (arrival.nextBus.minutesAway ?? -1) > 0 {
                        Text("to arrival")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }

            // Route
            Text("\(arrival.destination)")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)

            // Bus type badge + crowd indicator
            HStack(spacing: 8) {
                BusTypeBadge(busType: arrival.busType)
                BusOperatorBadge(busOperator: arrival.busOperator)
                CrowdIndicator(crowdLevel: arrival.crowdLevel)
                if arrival.isWheelchairAccessible {
                    Image(systemName: "figure.roll")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(theme.accent)
                        .accessibilityLabel("Wheelchair accessible")
                }
            }

            Divider()
                .background(theme.border)

            // Next arrivals + star
            HStack {
                if arrival.isOperating && (arrival.nextBus2.minutesAway != nil || arrival.nextBus3.minutesAway != nil) {
                    nextArrivalsView
                }

                Spacer()

                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onToggleFavourite()
                } label: {
                    Image(systemName: isFavourite ? "star.fill" : "star")
                        .foregroundColor(isFavourite ? theme.star : theme.textMuted)
                        .font(.system(.body, design: .monospaced))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavourite ? "Remove from favourites" : "Add to favourites")
            }
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPinned ? theme.accent : theme.border, lineWidth: isPinned ? 2 : 1)
        )
        .shadow(color: isPinned ? theme.accent.opacity(0.25) : .clear, radius: 8, y: 2)
        .opacity(arrival.isOperating ? 1.0 : 0.5)
        .animation(.snappy(duration: 0.3), value: isPinned)
    }

    private var primaryArrivalText: String {
        if !arrival.isOperating { return "Not in service" }
        guard let minutes = arrival.nextBus.minutesAway else { return "-" }
        if minutes <= 0 { return "Arr" }
        return "\(minutes) min"
    }

    private var primaryArrivalColor: Color {
        if !arrival.isOperating { return theme.textMuted }
        if arrival.nextBus.isArriving { return theme.arriving }
        if arrival.nextBus.isSoon { return theme.soon }
        return theme.textPrimary
    }

    private var nextArrivalsView: some View {
        HStack(spacing: 0) {
            Text("Next: ")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(theme.textSecondary)

            if let min2 = arrival.nextBus2.minutesAway {
                Text(min2 <= 0 ? "Arr" : "\(min2) min")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                    .contentTransition(.numericText())
            } else {
                Text("-")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(theme.textSecondary)
            }

            if let min3 = arrival.nextBus3.minutesAway {
                Text(" · then ")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(theme.textSecondary)
                Text(min3 <= 0 ? "Arr" : "\(min3) min")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                    .contentTransition(.numericText())
            }
        }
    }
}
