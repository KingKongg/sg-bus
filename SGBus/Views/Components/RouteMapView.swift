import SwiftUI

struct RouteMapView: View {
    let stops: [BusStop]

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
                            .fill(theme.textMuted)
                            .frame(width: 8, height: 8)

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
                        Text(stop.name)
                            .font(.system(.subheadline, design: .monospaced))
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
