import SwiftUI

struct CrowdIndicator: View {
    let crowdLevel: CrowdLevel

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < crowdLevel.dotCount ? crowdLevel.color : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            Text(crowdLevel.displayName)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(crowdLevel.color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Crowd level: \(crowdLevel.displayName)")
    }
}
