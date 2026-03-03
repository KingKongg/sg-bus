import SwiftUI

struct CrowdIndicator: View {
    let crowdLevel: CrowdLevel

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < crowdLevel.dotCount ? crowdLevel.color : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .animation(.easeOut(duration: 0.2).delay(Double(index) * 0.08), value: crowdLevel)
            }
            Text(crowdLevel.displayName)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(crowdLevel.color)
                .contentTransition(.interpolate)
                .animation(.easeOut(duration: 0.2), value: crowdLevel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Crowd level: \(crowdLevel.displayName)")
    }
}
