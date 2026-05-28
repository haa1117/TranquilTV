import SwiftUI

struct PlaybackSettingsPage: View {
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss
    private var theme: AppTheme { settings.currentTheme }

    private let hideOptions: [(label: String, seconds: Int)] = [
        ("3 seconds", 3),
        ("5 seconds", 5),
        ("10 seconds", 10),
        ("Never", 0),
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                settingsNavBar(title: "Playback")

                ScrollView {
                    VStack(spacing: 16) {
                        ToggleSettingsCard(
                            icon: "play.circle.fill",
                            title: "Auto-play Last Scene",
                            subtitle: "Resume where you left off on launch",
                            isOn: $settings.autoPlayLastScene
                        )

                        ToggleSettingsCard(
                            icon: "clock.badge.checkmark",
                            title: "Time-Based Suggestions",
                            subtitle: "Show scene suggestions based on time of day",
                            isOn: $settings.timeBasedSuggestionsEnabled
                        )

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.accentColor.opacity(0.2))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "eye.slash.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(theme.accentColor)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hide Controls After")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("During playback, controls auto-hide after inactivity")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }

                            HStack(spacing: 16) {
                                ForEach(hideOptions, id: \.seconds) { option in
                                    let isSelected = settings.controlsAutoHideSeconds == option.seconds
                                    TranquilFocusButton(action: {
                                        settings.controlsAutoHideSeconds = option.seconds
                                    }) { isFocused in
                                        Text(option.label)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(isSelected ? theme.accentColor : Color(hex: 0x1A1A1A))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(isFocused ? theme.accentColor : Color.white.opacity(0.25), lineWidth: 2)
                                            )
                                            .tvFocusStyle(isFocused: isFocused)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x1A1A1A)))
                    }
                    .padding(.horizontal, TranquilTheme.standardPadding)
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            AnalyticsService.logScreenView("playback_settings_screen")
        }
    }

    @ViewBuilder
    private func settingsNavBar(title: String) -> some View {
        HStack {
            FocusableCircleButton(icon: "chevron.left", size: 56) { dismiss() }
            Spacer()
            Text(title)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 56)
        }
        .padding(.horizontal, TranquilTheme.standardPadding)
        .padding(.vertical, 24)
    }
}

#Preview { PlaybackSettingsPage() }

struct ToggleSettingsCard: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        TranquilFocusButton(action: {
            isOn.toggle()
        }) { isFocused in
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.accentColor.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundColor(theme.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }

                Spacer()

                ZStack {
                    Capsule()
                        .fill(isOn ? theme.accentColor : Color.white.opacity(0.2))
                        .frame(width: 60, height: 32)
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .offset(x: isOn ? 14 : -14)
                }
                .animation(.easeInOut(duration: 0.2), value: isOn)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x1A1A1A)))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? theme.accentColor : Color.clear, lineWidth: 2.5)
            )
            .shadow(color: isFocused ? theme.accentColor.opacity(0.3) : .clear, radius: 12)
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}
