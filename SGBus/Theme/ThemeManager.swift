import SwiftUI

final class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = true

    var colorScheme: ColorScheme { isDarkMode ? .dark : .light }

    // MARK: - Backgrounds
    var background: Color { isDarkMode ? Color(hex: 0x0D0D0D) : Color(hex: 0xF5F5F5) }
    var surface: Color { isDarkMode ? Color(hex: 0x1A1A1A) : .white }
    var surfaceSecondary: Color { isDarkMode ? Color(hex: 0x242424) : Color(hex: 0xEEEEEE) }

    // MARK: - Text
    var textPrimary: Color { isDarkMode ? .white : Color(hex: 0x111111) }
    var textSecondary: Color { isDarkMode ? Color(hex: 0xAAAAAA) : Color(hex: 0x666666) }
    var textMuted: Color { isDarkMode ? Color(hex: 0x666666) : Color(hex: 0x999999) }

    // MARK: - Accent
    var accent: Color { Color(hex: 0x3A5CF5) }
    var accentSoft: Color { isDarkMode ? Color(hex: 0x3A5CF5, opacity: 0.15) : Color(hex: 0x3A5CF5, opacity: 0.1) }

    // MARK: - Semantic
    var arriving: Color { Color(hex: 0x3A5CF5) }
    var soon: Color { Color(hex: 0xD4A017) }
    var normal: Color { isDarkMode ? .white : Color(hex: 0x333333) }
    var star: Color { Color(hex: 0xFFD700) }
    var border: Color { isDarkMode ? Color(hex: 0x2A2A2A) : Color(hex: 0xDDDDDD) }

    // MARK: - Crowd
    var crowdLow: Color { Color(hex: 0x2E7D4F) }
    var crowdMedium: Color { Color(hex: 0x9A7500) }
    var crowdHigh: Color { Color(hex: 0xB03030) }

    func toggle() {
        isDarkMode.toggle()
    }
}
