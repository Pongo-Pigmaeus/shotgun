import SwiftUI

enum AppTheme {
    static let cornerRadius: CGFloat = 24
    static let compactCornerRadius: CGFloat = 16

    static let routeGradient = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.38, blue: 0.74),
            Color(red: 0.02, green: 0.62, blue: 0.48)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

extension Color {
    static let appTint = Color(red: 0.03, green: 0.42, blue: 0.62)
    static let appMint = Color(red: 0.00, green: 0.62, blue: 0.47)
    static let appCoral = Color(red: 0.93, green: 0.36, blue: 0.26)
    static let appGold = Color(red: 0.96, green: 0.68, blue: 0.20)
    static let appInk = Color(red: 0.08, green: 0.09, blue: 0.11)
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06))
            }
    }

    func compactCard(padding: CGFloat = 14) -> some View {
        self
            .padding(padding)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppTheme.compactCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.compactCornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06))
            }
    }
}

extension Date {
    var dayText: String {
        formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var timeText: String {
        formatted(.dateTime.hour().minute())
    }

    var shortDateTimeText: String {
        formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
    }
}
