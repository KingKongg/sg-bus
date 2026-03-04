import ActivityKit
import SwiftUI
import WidgetKit

struct ExpandedLeadingView: View {
    let context: ActivityViewContext<BusLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.serviceNo)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
            Text(context.attributes.destination)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.leading, 4)
    }
}

struct ExpandedTrailingView: View {
    let context: ActivityViewContext<BusLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let minutes = context.state.nextBusMinutes {
                Text(minutes <= 0 ? "Arr" : "\(minutes) min")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundColor(arrivalColor)
            } else {
                Text("-")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Text("to arrival")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var arrivalColor: Color {
        guard let min = context.state.nextBusMinutes else { return .secondary }
        if min <= 1 { return Color(hex: 0x3A5CF5) }
        if min <= 4 { return Color(hex: 0xD4A017) }
        return .primary
    }
}

struct ExpandedBottomView: View {
    let context: ActivityViewContext<BusLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Progress bar
            if let arrivalDate = context.state.nextBusArrivalDate {
                ProgressView(
                    timerInterval: Date.now...arrivalDate,
                    countsDown: true,
                    label: { EmptyView() },
                    currentValueLabel: { EmptyView() }
                )
                .tint(progressTint)
            }

            // Next buses row
            HStack(spacing: 0) {
                Text("Next: ")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)

                if let min2 = context.state.nextBus2Minutes {
                    Text("\(min2) min")
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                } else {
                    Text("-")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                if let min3 = context.state.nextBus3Minutes {
                    Text(" · then ")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("\(min3) min")
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }

    private var progressTint: Color {
        guard let min = context.state.nextBusMinutes else { return .white }
        if min <= 1 { return Color(hex: 0x3A5CF5) }
        if min <= 4 { return Color(hex: 0xD4A017) }
        return .white
    }
}
