import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(theme.textMuted)
            Text(title)
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(theme.textPrimary)
            Text(subtitle)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
