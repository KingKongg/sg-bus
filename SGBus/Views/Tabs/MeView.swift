import SwiftUI

struct MeView: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) { theme.toggle() }
                    } label: {
                        HStack {
                            Image(systemName: theme.isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(theme.accent)
                                .frame(width: 28)
                            Text("Appearance")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            Text(theme.isDarkMode ? "Dark" : "Light")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                } header: {
                    Text("Settings")
                        .font(.system(.caption, design: .monospaced))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Me")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
