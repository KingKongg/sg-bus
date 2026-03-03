import SwiftUI

struct RouteMapView: View {
    let stops: [BusStop]
    let currentStopId: String?

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                HStack(alignment: .top, spacing: 12) {
                    // Vertical line with dot
                    VStack(spacing: 0) {
                        if index > 0 {
                            Rectangle()
                                .fill(theme.accent)
                                .frame(width: 2, height: 16)
                        } else {
                            Spacer().frame(height: 16)
                        }

                        Circle()
                            .fill(stop.id == currentStopId ? theme.accent : theme.textMuted)
                            .frame(width: stop.id == currentStopId ? 12 : 8, height: stop.id == currentStopId ? 12 : 8)

                        if index < stops.count - 1 {
                            Rectangle()
                                .fill(theme.accent)
                                .frame(width: 2, height: 16)
                        } else {
                            Spacer().frame(height: 16)
                        }
                    }
                    .frame(width: 16)

                    // Stop info
                    VStack(alignment: .leading, spacing: 2) {
                        if stop.id == currentStopId {
                            Text("You are here")
                                .font(.system(.caption2, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(theme.accent)
                        }
                        Text(stop.name)
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(stop.id == currentStopId ? .bold : .regular)
                            .foregroundColor(theme.textPrimary)
                        Text(stop.road)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.vertical, 4)

                    Spacer()
                }
            }
        }
    }
}
