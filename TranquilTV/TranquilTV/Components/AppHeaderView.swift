import SwiftUI

struct AppHeaderView: View {
    let isPremium: Bool
    var focusNamespace: Namespace.ID? = nil
    let onSettingsTap: () -> Void
    let onUpgradeTap: () -> Void

    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        HStack {
            HStack(spacing: 24) {
                Image("app_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tranquil")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        Text("Meditate")
                        Circle().fill(Color.white.opacity(0.5)).frame(width: 5, height: 5)
                        Text("Sleep")
                        Circle().fill(Color.white.opacity(0.5)).frame(width: 5, height: 5)
                        Text("Relax")
                    }
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()

            HStack(spacing: 24) {
                if isPremium {
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 24))
                        Text("Premium")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Capsule())
                } else {
                    UpgradeButtonView(onTap: onUpgradeTap, focusNamespace: focusNamespace)
                }

                Button(action: onSettingsTap) {
                    HeaderSettingsLabel()
                }
                .tranquilTVButton()
            }
            .focusSection()
        }
        .padding(.horizontal, TranquilTheme.headerHorizontalPadding)
        .padding(.vertical, TranquilTheme.headerVerticalPadding)
    }
}

private struct HeaderSettingsLabel: View {
    @Environment(\.isFocused) private var isFocused
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        Image(systemName: "gearshape.fill")
            .font(.system(size: 34))
            .foregroundColor(.white.opacity(isFocused ? 1 : 0.85))
            .frame(width: 72, height: 72)
            .background(
                Circle()
                    .fill(isFocused ? theme.accentColor.opacity(0.35) : Color.white.opacity(0.1))
            )
            .overlay(
                Circle()
                    .stroke(isFocused ? theme.accentColor : Color.clear, lineWidth: 3)
            )
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct UpgradeButtonView: View {
    let onTap: () -> Void
    var focusNamespace: Namespace.ID? = nil

    var body: some View {
        Button(action: onTap) {
            UpgradeButtonLabel()
        }
        .tranquilTVButton()
    }
}

private struct UpgradeButtonLabel: View {
    @Environment(\.isFocused) private var isFocused
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        HStack(spacing: 12) {
            Text("🜲")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(theme.premiumBadgeColor)
            Text("Upgrade")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(theme.premiumBadgeColor)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: [
                    theme.upgradeGradientStart.opacity(isFocused ? 0.35 : 0.22),
                    theme.upgradeGradientEnd.opacity(isFocused ? 0.35 : 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(theme.premiumBadgeColor.opacity(isFocused ? 0.85 : 0.4),
                        lineWidth: isFocused ? 3 : 1.5)
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
