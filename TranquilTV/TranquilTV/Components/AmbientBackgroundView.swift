import SwiftUI

/// Animated ambient blobs — matches Android `AmbientBackground` (default theme only).
struct AmbientBackgroundView: View {
    @ObservedObject private var settings = SettingsService.shared
    @State private var blob1Scale: CGFloat = 0.95
    @State private var blob2Scale: CGFloat = 0.95

    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        if settings.currentThemeType != .defaultTheme {
            Color.clear
        } else {
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.05))
                    .frame(width: 600, height: 600)
                    .blur(radius: 60)
                    .scaleEffect(blob1Scale)
                    .offset(x: -200, y: -100)

                Circle()
                    .fill(theme.gradientColors.dropFirst().first?.opacity(0.05) ?? theme.accentColor.opacity(0.04))
                    .frame(width: 500, height: 500)
                    .blur(radius: 50)
                    .scaleEffect(blob2Scale)
                    .offset(x: 300, y: 200)
            }
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    blob1Scale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                        blob2Scale = 1.05
                    }
                }
            }
        }
    }
}
