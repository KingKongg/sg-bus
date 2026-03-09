import ActivityKit
import SwiftUI
import WidgetKit

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<BusLiveActivityAttributes>

    private var nextBusMinutes: Int? {
        minutesFrom(context.state.nextBusArrival)
    }

    private var nextBus2Minutes: Int? {
        minutesFrom(context.state.nextBus2Arrival)
    }

    private var nextBus3Minutes: Int? {
        minutesFrom(context.state.nextBus3Arrival)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Top row: bus info + arrival
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.serviceNo)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                    Text(context.attributes.destination)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let minutes = nextBusMinutes {
                        Text(minutes <= 0 ? "Arr" : "\(minutes) min")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .foregroundColor(arrivalColor)
                    } else {
                        Text("N/S")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    if let minutes = nextBusMinutes, minutes > 0 {
                        Text("to arrival")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Progress bar
            if let arrivalDate = context.state.nextBusArrival, arrivalDate > .now {
                ProgressView(
                    timerInterval: Date.now...arrivalDate,
                    countsDown: true
                ) {
                    EmptyView()
                }
                .tint(progressTint)
            }

            // Next buses
            HStack(spacing: 0) {
                Text("Next: ")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                if let min2 = nextBus2Minutes {
                    Text(min2 <= 0 ? "Arr" : "\(min2) min")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                } else {
                    Text("-")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                if let min3 = nextBus3Minutes {
                    Text(" · then ")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(min3 <= 0 ? "Arr" : "\(min3) min")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                Spacer()

                Text(context.attributes.stopName)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .activityBackgroundTint(.black.opacity(0.85))
    }

    private var arrivalColor: Color {
        guard let min = nextBusMinutes else { return .secondary }
        if min <= 1 { return Color(hex: 0x3A5CF5) }
        if min <= 4 { return Color(hex: 0xD4A017) }
        return .primary
    }

    private var progressTint: Color {
        guard let min = nextBusMinutes else { return .white }
        if min <= 1 { return Color(hex: 0x3A5CF5) }
        if min <= 4 { return Color(hex: 0xD4A017) }
        return .white
    }

    private func minutesFrom(_ date: Date?) -> Int? {
        guard let date else { return nil }
        return max(0, Int(date.timeIntervalSince(Date.now) / 60))
    }
}
