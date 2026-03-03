import SwiftUI

struct BusArrivalRow: View {
    let arrival: BusArrival
    let isFavourite: Bool
    let onToggleFavourite: () -> Void

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            // Bus number square
            Text(arrival.serviceNo)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(theme.textPrimary)
                .frame(width: 56, height: 56)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )

            // Middle: service info
            VStack(alignment: .leading, spacing: 4) {
                // Type badge + star
                HStack(spacing: 6) {
                    BusTypeBadge(busType: arrival.busType)

                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onToggleFavourite()
                    } label: {
                        Image(systemName: isFavourite ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(isFavourite ? theme.star : theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }

                // Destination
                Text(arrival.destination)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(theme.textSecondary)

                // Crowd indicator
                CrowdIndicator(crowdLevel: arrival.crowdLevel)
            }

            Spacer()

            // Right: arrival times
            VStack(alignment: .trailing, spacing: 4) {
                Text(primaryArrivalText)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(primaryArrivalColor)

                // Next two arrivals
                if arrival.nextBus2.minutesAway != nil || arrival.nextBus3.minutesAway != nil {
                    HStack(spacing: 0) {
                        if let min2 = arrival.nextBus2.minutesAway {
                            Text("\(min2) min")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(theme.textSecondary)
                        }
                        if arrival.nextBus2.minutesAway != nil && arrival.nextBus3.minutesAway != nil {
                            Text(" · ")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(theme.textMuted)
                        }
                        if let min3 = arrival.nextBus3.minutesAway {
                            Text("\(min3) min")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private var primaryArrivalText: String {
        guard let minutes = arrival.nextBus.minutesAway else { return "-" }
        if minutes <= 0 { return "Arr" }
        return "\(minutes) min"
    }

    private var primaryArrivalColor: Color {
        if arrival.nextBus.isArriving { return theme.arriving }
        if arrival.nextBus.isSoon { return theme.soon }
        return theme.textPrimary
    }
}
