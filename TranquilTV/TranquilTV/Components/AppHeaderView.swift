import SwiftUI

struct AppHeaderView: View {
    let isPremium: Bool
    let onSettingsTap: () -> Void
    let onUpgradeTap: () -> Void

    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image("app_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text("Tranquil")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)

                Text("Meditate, Sleep & Relax")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            HStack(spacing: 20) {
                if isPremium {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 16))
                        Text("Premium")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Capsule())
                } else {
                    Button(action: onUpgradeTap) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                            Text("Upgrade")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [theme.accentColor.opacity(0.8), theme.accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .tvFocusStyle()
                }

                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .tvFocusStyle()
            }
        }
        .padding(.horizontal, TranquilTheme.standardPadding)
        .padding(.vertical, 24)
    }
}
