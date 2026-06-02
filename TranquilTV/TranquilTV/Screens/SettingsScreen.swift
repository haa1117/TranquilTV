import SwiftUI

struct SettingsScreen: View {
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPage: SettingsPage? = nil

    private var theme: AppTheme { settings.currentTheme }

    enum SettingsPage: Hashable {
        case theme, audio, sleepTimer, about, privacy
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: theme.gradientColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        FocusableCircleButton(icon: "chevron.left", size: 56) {
                            dismiss()
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))
                                .foregroundColor(theme.accentColor)
                            Text("Settings")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Color.clear.frame(width: 56)
                    }
                    .padding(.horizontal, TranquilTheme.standardPadding)
                    .padding(.vertical, 24)

                    // Settings list
                    ScrollView {
                        VStack(spacing: 16) {
                            SettingsCardView(
                                icon: "paintpalette.fill",
                                title: "Theme",
                                subtitle: settings.currentTheme.name
                            ) {
                                selectedPage = .theme
                            }
                            SettingsCardView(
                                icon: "speaker.wave.3.fill",
                                title: "Audio",
                                subtitle: "Volume: \(Int(settings.defaultVolume * 100))%"
                            ) {
                                selectedPage = .audio
                            }
                            SettingsCardView(
                                icon: "clock.fill",
                                title: "Sleep Timer",
                                subtitle: "Default: \(settings.defaultSleepTimerMinutes) min"
                            ) {
                                selectedPage = .sleepTimer
                            }
                            SettingsCardView(
                                icon: "info.circle.fill",
                                title: "About",
                                subtitle: "Version 1.0.0"
                            ) {
                                selectedPage = .about
                            }
                            SettingsCardView(
                                icon: "shield.fill",
                                title: "Privacy Policy",
                                subtitle: "How we handle your data"
                            ) {
                                selectedPage = .privacy
                            }
                        }
                        .padding(.horizontal, TranquilTheme.standardPadding)
                        .padding(.bottom, 60)
                    }
                }
            }
            .navigationDestination(for: SettingsPage.self) { page in
                switch page {
                case .theme: ThemeSettingsPage()
                case .audio: AudioSettingsPage()
                case .sleepTimer: SleepTimerSettingsPage()
                case .about: AboutSettingsPage()
                case .privacy: PrivacyPolicyPage()
                }
            }
        }
        .onAppear {
            AnalyticsService.logScreenView("settings_screen")
        }
    }
}

struct SettingsCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    let onTap: () -> Void

    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        TranquilFocusButton(action: onTap) { isFocused in
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
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 22))
                    .foregroundColor(isFocused ? theme.accentColor : .white.opacity(0.4))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: 0x1A1A1A))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? theme.accentColor : Color.clear, lineWidth: 2.5)
            )
            .shadow(color: isFocused ? theme.accentColor.opacity(0.3) : .clear, radius: 12)
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Settings

struct ThemeSettingsPage: View {
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                settingsNavBar(title: "Theme")
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(AppTheme.allThemes, id: \.type) { t in
                            themeRow(t)
                        }
                    }
                    .padding(.horizontal, TranquilTheme.standardPadding)
                    .padding(.bottom, 60)
                }
            }
        }
    }

    @ViewBuilder
    private func themeRow(_ t: AppTheme) -> some View {
        let isSelected = settings.currentThemeType == t.type
        TranquilFocusButton(action: {
            settings.currentThemeType = t.type
        }) { isFocused in
            HStack(spacing: 20) {
                // Color swatch
                HStack(spacing: 4) {
                    ForEach(0..<min(3, t.gradientColors.count), id: \.self) { i in
                        Circle().fill(t.gradientColors[i]).frame(width: 20, height: 20)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(t.name)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x1A1A1A)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2.5))
        }
        .buttonStyle(.plain)
        .tvFocusStyle()
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

// MARK: - Audio Settings

struct AudioSettingsPage: View {
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    FocusableCircleButton(icon: "chevron.left", size: 56) { dismiss() }
                    Spacer()
                    Text("Audio").font(.system(size: 34, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 56)
                }
                .padding(.horizontal, TranquilTheme.standardPadding)
                .padding(.vertical, 24)

                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Volume")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                        HStack(spacing: 12) {
                            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { level in
                                let isSelected = abs(settings.defaultVolume - level) < 0.01
                                TranquilFocusButton(action: {
                                    settings.defaultVolume = level
                                }) { isFocused in
                                    Text("\(Int(level * 100))%")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(isSelected ? theme.accentColor : Color(hex: 0x1A1A1A))
                                        )
                                        .tvFocusStyle(isFocused: isFocused)
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x1A1A1A)))
                }
                .padding(.horizontal, TranquilTheme.standardPadding)
                Spacer()
            }
        }
    }
}

// MARK: - Sleep Timer Settings

struct SleepTimerSettingsPage: View {
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss
    private var theme: AppTheme { settings.currentTheme }
    private let options = [15, 30, 45, 60, 90, 120]

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    FocusableCircleButton(icon: "chevron.left", size: 56) { dismiss() }
                    Spacer()
                    Text("Sleep Timer").font(.system(size: 34, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 56)
                }
                .padding(.horizontal, TranquilTheme.standardPadding)
                .padding(.vertical, 24)

                Text("Default Timer Duration")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(options, id: \.self) { mins in
                            let isSelected = settings.defaultSleepTimerMinutes == mins
                            Button { settings.defaultSleepTimerMinutes = mins } label: {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(theme.accentColor)
                                        .font(.system(size: 22))
                                    Text("\(mins) minutes")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(theme.accentColor)
                                            .font(.system(size: 28))
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 18)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x1A1A1A)))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2.5))
                            }
                            .buttonStyle(.plain)
                            .tvFocusStyle()
                        }
                    }
                    .padding(.horizontal, TranquilTheme.standardPadding)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

// MARK: - About

struct AboutSettingsPage: View {
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 32) {
                HStack {
                    FocusableCircleButton(icon: "chevron.left", size: 56) { dismiss() }
                    Spacer()
                    Text("About").font(.system(size: 34, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 56)
                }
                .padding(.horizontal, TranquilTheme.standardPadding)
                .padding(.top, 24)

                VStack(spacing: 16) {
                    Image("app_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))

                    Text("Tranquil")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)

                    Text("Meditate, Sleep & Relax")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Version 1.0.0")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 8)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyPage: View {
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    FocusableCircleButton(icon: "chevron.left", size: 56) { dismiss() }
                    Spacer()
                    Text("Privacy Policy").font(.system(size: 34, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 56)
                }
                .padding(.horizontal, TranquilTheme.standardPadding)
                .padding(.vertical, 24)

                ScrollView {
                    Text("""
Tranquil Privacy Policy

Tranquil collects minimal data necessary to operate the app. We do not sell or share your personal information with third parties.

Data We Collect:
• App usage analytics (anonymous)
• Crash reports (anonymous)
• Purchase history (via Apple App Store, no card data stored by us)

Your preferences (theme, sleep timer, favorites) are stored locally on your device.

Contact: support@futurewatch.co
""")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, TranquilTheme.standardPadding)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

#Preview { SettingsScreen() }
