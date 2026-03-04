import ActivityKit
import SwiftUI
import WidgetKit

struct CompactLeadingView: View {
    let context: ActivityViewContext<BusLiveActivityAttributes>

    var body: some View {
        ZStack {
            if let arrivalDate = context.state.nextBusArrivalDate {
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
        guard let min = context.state.nextBusMinutes else { return .white }
        if min <= 1 { return Color(hex: 0x3A5CF5) }
        if min <= 4 { return Color(hex: 0xD4A017) }
        return .white
    }
}

struct CompactTrailingView: View {
    let context: ActivityViewContext<BusLiveActivityAttributes>

    var body: some View {
        if let minutes = context.state.nextBusMinutes {
            Text(minutes <= 0 ? "Arr" : "\(minutes)m")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundColor(arrivalColor)
        } else {
            Text("-")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
        }
    }

    private var arrivalColor: Color {
        guard let min = context.state.nextBusMinutes else { return .secondary }
        if min <= 1 { return Color(hex: 0x3A5CF5) }
        if min <= 4 { return Color(hex: 0xD4A017) }
        return .primary
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
