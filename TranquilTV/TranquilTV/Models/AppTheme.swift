import SwiftUI

enum AppThemeType: String, CaseIterable, Codable {
    case defaultTheme = "default"
    case calmOcean = "calm_ocean"
    case forestMist = "forest_mist"
    case sunsetGlow = "sunset_glow"
    case nightSerenity = "night_serenity"
}

struct AppTheme {
    let type: AppThemeType
    let name: String
    let gradientColors: [Color]
    let accentColor: Color
    let backgroundColor: Color
    let textColor: Color

    var gradient: LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
    }

    static let defaultTheme = AppTheme(
        type: .defaultTheme,
        name: "Default",
        gradientColors: [Color(hex: 0x0A1224), Color(hex: 0x060A12), Color(hex: 0x0B1220)],
        accentColor: Color(hex: 0x00BCD4),
        backgroundColor: Color(hex: 0x080D18),
        textColor: .white
    )

    static let calmOcean = AppTheme(
        type: .calmOcean,
        name: "Calm Ocean",
        gradientColors: [Color(hex: 0x0D1B2A), Color(hex: 0x1B263B)],
        accentColor: Color(hex: 0x4A90E2),
        backgroundColor: Color(hex: 0x0D1B2A),
        textColor: .white
    )

    static let forestMist = AppTheme(
        type: .forestMist,
        name: "Forest Mist",
        gradientColors: [Color(hex: 0x1A3A2E), Color(hex: 0x2D4A3E)],
        accentColor: Color(hex: 0x6B9F78),
        backgroundColor: Color(hex: 0x1A3A2E),
        textColor: .white
    )

    static let sunsetGlow = AppTheme(
        type: .sunsetGlow,
        name: "Sunset Glow",
        gradientColors: [Color(hex: 0x2D1B3D), Color(hex: 0x4A2C5A)],
        accentColor: Color(hex: 0xE8A87C),
        backgroundColor: Color(hex: 0x2D1B3D),
        textColor: .white
    )

    static let nightSerenity = AppTheme(
        type: .nightSerenity,
        name: "Night Serenity",
        gradientColors: [Color(hex: 0x0F0C29), Color(hex: 0x1A1A2E)],
        accentColor: Color(hex: 0x9B59B6),
        backgroundColor: Color(hex: 0x0F0C29),
        textColor: .white
    )

    static let allThemes: [AppTheme] = [defaultTheme, calmOcean, forestMist, sunsetGlow, nightSerenity]

    static func theme(for type: AppThemeType) -> AppTheme {
        allThemes.first { $0.type == type } ?? defaultTheme
    }
}
