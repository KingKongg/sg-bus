import ActivityKit
import SwiftUI
import WidgetKit

struct CompactLeadingView: View {
    let context: ActivityViewContext<BusLiveActivityAttributes>

    private var nextBusMinutes: Int? {
        minutesFrom(context.state.nextBusArrival)
    }

    var body: some View {
        ZStack {
            if let arrivalDate = context.state.nextBusArrival, arrivalDate > .now {
                ProgressView(
                    timerInterval: Date.now...arrivalDate,
                    countsDown: true,
                    label: { EmptyView() },
                    currentValueLabel: { EmptyView() }
                )
                .progressViewStyle(.circular)
                .tint(arrivalTint)
                .frame(width: 24, height: 24)
            }

            Text(context.attributes.serviceNo)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .minimumScaleFactor(0.6)
        }
    }

    private var arrivalTint: Color {
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

struct CompactTrailingView: View {
    let context: ActivityViewContext<BusLiveActivityAttributes>

    private var nextBusMinutes: Int? {
        minutesFrom(context.state.nextBusArrival)
    }

    var body: some View {
        if let minutes = nextBusMinutes {
            Text(minutes <= 0 ? "Arr" : "\(minutes)m")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundColor(arrivalColor)
        } else {
            Text("N/S")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var arrivalColor: Color {
        guard let min = nextBusMinutes else { return .secondary }
        if min <= 1 { return Color(hex: 0x3A5CF5) }
        if min <= 4 { return Color(hex: 0xD4A017) }
        return .primary
    }

    private func minutesFrom(_ date: Date?) -> Int? {
        guard let date else { return nil }
        return max(0, Int(date.timeIntervalSince(Date.now) / 60))
    }
}

struct MinimalView: View {
    let context: ActivityViewContext<BusLiveActivityAttributes>

    var body: some View {
        Text(context.attributes.serviceNo)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .minimumScaleFactor(0.5)
    }
}
