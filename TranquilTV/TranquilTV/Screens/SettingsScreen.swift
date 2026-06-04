import SwiftUI

// MARK: - Settings Screen (two-panel TV layout)

struct SettingsScreen: View {
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var activePage: SettingsPage = .theme

    private var theme: AppTheme { settings.currentTheme }

    enum SettingsPage: CaseIterable {
        case theme, audio, sleepTimer, about, privacy, privacyLink, termsLink

        var title: String {
            switch self {
            case .theme:       return "Theme"
            case .audio:       return "Audio"
            case .sleepTimer:  return "Sleep Timer"
            case .about:       return "About"
            case .privacy:     return "Privacy Policy"
            case .privacyLink: return "Company Privacy"
            case .termsLink:   return "Terms of Service"
            }
        }
        var icon: String {
            switch self {
            case .theme:       return "paintpalette.fill"
            case .audio:       return "speaker.wave.3.fill"
            case .sleepTimer:  return "clock.fill"
            case .about:       return "info.circle.fill"
            case .privacy:     return "shield.fill"
            case .privacyLink: return "globe"
            case .termsLink:   return "doc.text.fill"
            }
        }
        var isExternalLink: Bool {
            self == .privacyLink || self == .termsLink
        }
        var externalURLString: String? {
            switch self {
            case .privacyLink: return "futurewatch.co/privacy"
            case .termsLink:   return "futurewatch.co/terms"
            default: return nil
            }
        }
    }

    var body: some View {
        ZStack {
            // Full-bleed background
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle ambient blobs
            GeometryReader { geo in
                Circle()
                    .fill(theme.accentColor.opacity(0.06))
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: -geo.size.width * 0.1, y: -geo.size.height * 0.1)
                    .blur(radius: 80)
                Circle()
                    .fill(theme.accentColor.opacity(0.04))
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: geo.size.width * 0.7, y: geo.size.height * 0.6)
                    .blur(radius: 80)
            }
            .ignoresSafeArea()

            HStack(spacing: 0) {
                // ── Left sidebar ──────────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {
                    // Back + app identity
                    HStack(spacing: 20) {
                        FocusableCircleButton(icon: "chevron.left", size: 68) {
                            dismiss()
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Settings")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            Text("Tranquil")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white.opacity(0.45))
                        }
                    }
                    .padding(.top, 52)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 36)

                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 28)

                    // Nav items
                    VStack(spacing: 6) {
                        ForEach(SettingsPage.allCases, id: \.title) { page in
                            SidebarItem(
                                page: page,
                                isActive: activePage == page,
                                accentColor: theme.accentColor
                            ) {
                                activePage = page
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .frame(width: 440)
                .background(Color.black.opacity(0.25))

                // Thin separator
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1)

                // ── Right content panel ───────────────────────────────────
                ZStack {
                    switch activePage {
                    case .theme:       ThemePanel()
                    case .audio:       AudioPanel()
                    case .sleepTimer:  SleepTimerPanel()
                    case .about:       AboutPanel()
                    case .privacy:     PrivacyPanel()
                    case .privacyLink:
                        ExternalURLPanel(title: "Company Privacy Policy", urlString: "futurewatch.co/privacy")
                    case .termsLink:
                        ExternalURLPanel(title: "Company Terms of Service", urlString: "futurewatch.co/terms")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            AnalyticsService.logScreenView("settings_screen")
        }
    }
}

// MARK: - Sidebar item

private struct SidebarItem: View {
    let page: SettingsScreen.SettingsPage
    let isActive: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        TranquilFocusButton(action: onTap) { isFocused in
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isActive
                              ? accentColor.opacity(0.25)
                              : Color.white.opacity(isFocused ? 0.1 : 0.06))
                        .frame(width: 64, height: 64)
                    Image(systemName: page.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isActive ? accentColor : .white.opacity(0.7))
                }

                Text(page.title)
                    .font(.system(size: 28, weight: isActive ? .bold : .medium))
                    .foregroundColor(isActive ? .white : .white.opacity(0.65))

                Spacer()

                if page.isExternalLink {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 20))
                        .foregroundColor(accentColor.opacity(0.7))
                } else if isActive {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor)
                        .frame(width: 5, height: 36)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isActive
                          ? accentColor.opacity(0.12)
                          : Color.white.opacity(isFocused ? 0.06 : 0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isFocused && !isActive ? accentColor.opacity(0.5) : Color.clear,
                            lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .animation(.easeInOut(duration: 0.15), value: isActive)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Panel header

private struct PanelHeader: View {
    let icon: String
    let title: String
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.accentColor.opacity(0.18))
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(theme.accentColor)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                Rectangle()
                    .fill(theme.accentColor.opacity(0.6))
                    .frame(width: 52, height: 4)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Theme Panel

private struct ThemePanel: View {
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PanelHeader(icon: "paintpalette.fill", title: "Theme")

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)],
                    spacing: 20
                ) {
                    ForEach(AppTheme.allThemes, id: \.type) { t in
                        ThemeCard(t: t, isSelected: settings.currentThemeType == t.type, accentColor: theme.accentColor) {
                            settings.currentThemeType = t.type
                        }
                    }
                }
            }
            .padding(48)
        }
    }
}

private struct ThemeCard: View {
    let t: AppTheme
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        TranquilFocusButton(action: onTap) { isFocused in
            VStack(alignment: .leading, spacing: 14) {
                // Gradient preview strip
                HStack(spacing: 0) {
                    ForEach(0..<t.gradientColors.count, id: \.self) { i in
                        t.gradientColors[i]
                    }
                }
                .frame(height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                HStack {
                    Text(t.name)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(accentColor)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentColor : (isFocused ? accentColor.opacity(0.6) : Color.clear),
                            lineWidth: isSelected ? 2.5 : 1.5)
            )
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Audio Panel

private struct AudioPanel: View {
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }
    private let levels: [Double] = [0.25, 0.5, 0.75, 1.0]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeader(icon: "speaker.wave.3.fill", title: "Audio")

            VStack(alignment: .leading, spacing: 28) {
                Text("Default Playback Volume")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Text("Sets the app's starting volume level. Use your Apple TV remote to adjust system volume during playback.")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.top, -12)

                HStack(spacing: 20) {
                    ForEach(levels, id: \.self) { level in
                        let isSelected = abs(settings.defaultVolume - level) < 0.01
                        TranquilFocusButton(action: { settings.defaultVolume = level }) { isFocused in
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? theme.accentColor : Color.white.opacity(0.08))
                                        .frame(width: 100, height: 100)
                                    Image(systemName: volumeIcon(for: level))
                                        .font(.system(size: 36))
                                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                }
                                Text("\(Int(level * 100))%")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isSelected ? theme.accentColor.opacity(0.15) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isFocused ? theme.accentColor.opacity(0.7) : Color.clear, lineWidth: 2.5)
                            )
                            .scaleEffect(isFocused ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: isFocused)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .focusSection()

                ToggleSettingsCard(
                    icon: "moon.fill",
                    title: "Dim Screen",
                    subtitle: "Darken the screen during audio playback",
                    isOn: Binding(
                        get: { settings.audioOnlyMode },
                        set: { settings.audioOnlyMode = $0 }
                    )
                )
            }
            .padding(48)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05)))
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func volumeIcon(for level: Double) -> String {
        if level <= 0.25 { return "speaker.wave.1.fill" }
        if level <= 0.5  { return "speaker.wave.1.fill" }
        if level <= 0.75 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }
}

// MARK: - Sleep Timer Panel

private struct SleepTimerPanel: View {
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }
    // 0 = Off
    private let options = [0, 15, 30, 45, 60, 90, 120]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PanelHeader(icon: "clock.fill", title: "Sleep Timer")

                Text("Auto-stop playback after a set time. Great for falling asleep.")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 40)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 28),
                              GridItem(.flexible(), spacing: 28),
                              GridItem(.flexible(), spacing: 28),
                              GridItem(.flexible(), spacing: 28)],
                    spacing: 28
                ) {
                    ForEach(options, id: \.self) { mins in
                        let isSelected = settings.defaultSleepTimerMinutes == mins
                        TranquilFocusButton(action: { settings.defaultSleepTimerMinutes = mins }) { isFocused in
                            VStack(spacing: 16) {
                                if mins == 0 {
                                    Image(systemName: "moon.zzz.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(isSelected ? theme.accentColor : .white.opacity(0.6))
                                    Text("Off")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(isSelected ? theme.accentColor : .white)
                                } else {
                                    Text("\(mins)")
                                        .font(.system(size: 56, weight: .bold))
                                        .foregroundColor(isSelected ? theme.accentColor : .white)
                                    Text("min")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(isSelected ? theme.accentColor.opacity(0.8) : .white.opacity(0.5))
                                }
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(theme.accentColor)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .padding(.vertical, 48)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(isSelected ? theme.accentColor.opacity(0.15) : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(isSelected ? theme.accentColor : (isFocused ? theme.accentColor.opacity(0.6) : Color.clear),
                                            lineWidth: isSelected ? 3 : 2)
                            )
                            .scaleEffect(isFocused ? 1.04 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: isFocused)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(48)
        }
    }
}

// MARK: - About Panel

private struct AboutPanel: View {
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PanelHeader(icon: "info.circle.fill", title: "About")

            VStack(spacing: 28) {
                // App identity card
                HStack(spacing: 32) {
                    Image("app_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: theme.accentColor.opacity(0.35), radius: 24)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tranquil")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                        Text("Meditate, Sleep & Relax")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Version 1.0.0")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(theme.accentColor.opacity(0.9))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 7)
                            .background(theme.accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 32)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05)))

                // Details card
                VStack(alignment: .leading, spacing: 0) {
                    AboutRow(label: "Developer", value: "FutureWatch", icon: "building.2.fill", accentColor: theme.accentColor)
                    Divider().background(Color.white.opacity(0.08)).padding(.vertical, 2)
                    AboutRow(label: "Platform", value: "Apple TV", icon: "appletv.fill", accentColor: theme.accentColor)
                    Divider().background(Color.white.opacity(0.08)).padding(.vertical, 2)
                    AboutRow(label: "Support", value: "info@futurewatch.co", icon: "envelope.fill", accentColor: theme.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05)))
            }
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct AboutRow: View {
    let label: String
    let value: String
    let icon: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(accentColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                Text(value)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Privacy Panel

private struct PrivacyPanel: View {
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    private var privacySections: [String] {
        privacyText
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private let privacyText = """
Privacy Policy for Tranquil: Sleep & Relax
Last updated: March 2026

Introduction
FutureWatch ("we", "our", or "us") operates the Tranquil: Sleep & Relax application across Android, Android TV, iOS, and tvOS platforms.
This Privacy Policy explains how information may be collected, used, disclosed, and protected when you use the application.
By using the app, you agree to the practices described in this Privacy Policy.

No Account Required
Tranquil: Sleep & Relax does not require users to create an account or provide personal information to use the application.
Users can access the core features of the app without registration or login.
We do not collect usernames, passwords, or profile information for normal app usage.

In-App Purchases and Subscriptions
The app may offer subscriptions and one-time purchases that unlock premium content or remove advertisements.
Payments and subscriptions are securely processed through:
Google Play Billing (Android / Android TV)
Apple In-App Purchases (iOS / tvOS)
We do not collect, process, or store your credit card information or payment details directly.
Payment information is handled entirely by Google or Apple according to their own privacy policies.
For more information:
Google Privacy Policy:
 Google Privacy Policy
Apple Privacy Policy:
 Apple Privacy Policy

Advertising
Free versions of the application may display advertisements.
The app may use the following advertising providers:
Google AdMob
Unity Ads
These services may automatically collect certain information from devices, including:
Advertising identifiers
Device identifiers
Device model and operating system
IP address
Language settings
Approximate location derived from IP address
App interaction information
Ad engagement and performance data
This information is used to:
Deliver advertisements
Limit repetitive ads
Measure advertising performance
Improve advertising relevance
Detect fraud and abuse
Advertising providers may use collected information according to their own privacy policies.
Learn more:
Google AdMob Privacy & Terms
Unity Privacy Policy
Users may reset or limit advertising identifiers through their device settings.

Analytics and Diagnostic Information
The app uses analytics and diagnostic tools, including Google Analytics for Firebase, to understand app usage and improve stability and performance.
Analytics services may automatically collect information such as:
App interactions
Device type
Operating system version
Session duration
Crash reports
Performance and diagnostic data
General usage statistics
This information is used to:
Improve app performance and reliability
Fix crashes and technical issues
Understand feature usage
Improve user experience
Analytics information is aggregated and does not directly identify individual users.
Learn more:
Google Firebase Privacy Information

Health and Wellness Information
Tranquil: Sleep & Relax provides ambient scenes, meditation experiences, calming audio, and relaxation content intended for entertainment and general wellness purposes only.
The app does not:
collect health records
access Apple HealthKit or Google Health Connect
track sleep activity
monitor stress levels
monitor physical activity
process medical information
store personal wellness metrics
The application does not provide medical advice, diagnosis, or treatment.
All experiences provided by the app are passive relaxation and ambient media experiences.

How We Use Information
Information collected through the app may be used to:
Provide and maintain app functionality
Process subscriptions and purchases
Display advertisements
Improve app stability and reliability
Analyze usage trends
Respond to support requests
Prevent abuse and fraudulent activity

Third-Party Services
The application may use third-party services that collect and process information, including:
Google AdMob
Unity Ads
Google Analytics for Firebase
Google Play Billing
Apple In-App Purchases
Each third-party provider operates under its own privacy policies and terms.

Data Retention
We retain information only for as long as necessary to:
operate the application
improve services
comply with legal obligations
resolve disputes
enforce agreements
Anonymous analytics and diagnostic information may be retained for service improvement purposes.
Support communications may be retained for customer support and legal compliance purposes.

Data Deletion
Users may request deletion of any personal information associated with support communications by contacting us.
Users may also stop all app-related data collection by uninstalling the application from their device.
To request deletion of support-related information, contact:
Email: info@futurewatch.co
We will process deletion requests within a reasonable timeframe unless retention is required by law.

Children's Privacy
Tranquil: Sleep & Relax is not directed toward children under the age of 13.
We do not knowingly collect personal information from children.
If we become aware that personal information from a child has been collected, we will take reasonable steps to delete the information.
Parents or guardians may contact us regarding concerns about children's privacy.

Security
We take reasonable technical and organizational measures to protect information collected through the app.
However, no method of electronic storage or internet transmission can be guaranteed to be completely secure.

International Users
The application may be accessed from countries outside your place of residence.
Information collected through third-party services may be processed and stored in countries where data protection laws may differ from your jurisdiction.
By using the application, you consent to such processing where permitted by law.

Your Privacy Choices
Depending on your device and region, you may be able to:
Reset advertising identifiers
Limit ad personalization
Disable analytics permissions through device settings
Manage app permissions through device settings
iOS users may also manage tracking permissions through Apple's App Tracking Transparency settings.

Changes to This Privacy Policy
We may update this Privacy Policy from time to time.
Changes will be posted on this page with an updated revision date.
Continued use of the application after changes become effective constitutes acceptance of the updated Privacy Policy.

Contact Us
If you have questions about this Privacy Policy or wish to request data deletion, contact us:
Developer: FutureWatch
Email: info@futurewatch.co
"""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.accentColor.opacity(0.18))
                        .frame(width: 80, height: 80)
                    Image(systemName: "shield.fill")
                        .font(.system(size: 36))
                        .foregroundColor(theme.accentColor)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Privacy Policy")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                    Text("Navigate with the remote to scroll")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
            }
            .padding(.horizontal, 48)
            .padding(.top, 48)
            .padding(.bottom, 32)

            // Scrollable content — each paragraph is a focusable card.
            // tvOS focus engine scrolls the list automatically as the user
            // navigates down, giving natural remote-driven scrolling.
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(privacySections.enumerated()), id: \.offset) { index, section in
                            PrivacySectionCard(
                                text: section,
                                isTitle: index == 0,
                                accentColor: theme.accentColor
                            )
                            .id(index)
                        }

                    }
                    .padding(.horizontal, 48)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

// MARK: - External URL Panel

private enum URLPanelFocusField: Hashable { case openBrowser, showQR }

private struct ExternalURLPanel: View {
    let title: String
    let urlString: String

    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.openURL) private var openURL
    @State private var showQR = false
    @FocusState private var focused: URLPanelFocusField?
    private var theme: AppTheme { settings.currentTheme }
    private var fullURL: URL { URL(string: "https://\(urlString)")! }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 48) {
                // Icon + title
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.12))
                            .frame(width: 140, height: 140)
                        Image(systemName: "globe")
                            .font(.system(size: 64))
                            .foregroundColor(theme.accentColor)
                    }

                    Text(title)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("https://\(urlString)")
                        .font(.system(size: 26, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.accentColor.opacity(0.8))
                }

                // Buttons
                VStack(spacing: 20) {
                    Button {
                        openURL(fullURL) { accepted in
                            if !accepted { withAnimation { showQR = true } }
                        }
                    } label: {
                        URLPanelButtonLabel(
                            icon: "safari",
                            label: "Open in Browser",
                            isPrimary: true,
                            isFocused: focused == .openBrowser,
                            theme: theme
                        )
                    }
                    .tranquilTVButton()
                    .focused($focused, equals: .openBrowser)

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { showQR.toggle() }
                    } label: {
                        URLPanelButtonLabel(
                            icon: "qrcode",
                            label: showQR ? "Hide QR Code" : "Show QR Code",
                            isPrimary: false,
                            isFocused: focused == .showQR,
                            theme: theme
                        )
                    }
                    .tranquilTVButton()
                    .focused($focused, equals: .showQR)
                }
                .frame(maxWidth: 560)

                // QR code
                if showQR {
                    VStack(spacing: 24) {
                        Text("Scan with your phone")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))

                        QRCodeView(urlString: "https://\(urlString)")
                            .frame(width: 280, height: 280)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .frame(maxWidth: 680)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear { focused = .openBrowser }
    }
}

private struct URLPanelButtonLabel: View {
    let icon: String
    let label: String
    let isPrimary: Bool
    let isFocused: Bool
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
            Text(label)
                .font(.system(size: 30, weight: .bold))
        }
        .foregroundColor(isPrimary ? .white : (isFocused ? .white : .white.opacity(0.7)))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(isPrimary
                      ? (isFocused ? theme.accentColor : theme.accentColor.opacity(0.7))
                      : Color.white.opacity(isFocused ? 0.12 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(isFocused ? (isPrimary ? Color.white.opacity(0.4) : theme.accentColor) : Color.clear,
                        lineWidth: 2.5)
        )
        .scaleEffect(isFocused ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

private struct QRCodeView: View {
    let urlString: String

    var body: some View {
        if let qrImage = generateQRCode(from: urlString) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Image(systemName: "qrcode")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.3))
                )
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scale = 10.0
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// Each paragraph is a focusable card — tvOS focus engine drives scrolling.
private struct PrivacySectionCard: View {
    let text: String
    let isTitle: Bool
    let accentColor: Color

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: {}) {
            PrivacySectionCardLabel(text: text, isTitle: isTitle, accentColor: accentColor)
        }
        .tranquilTVButton()
    }
}

private struct PrivacySectionCardLabel: View {
    let text: String
    let isTitle: Bool
    let accentColor: Color

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Text(text)
            .font(.system(size: isTitle ? 38 : 28, weight: isTitle ? .bold : .regular))
            .foregroundColor(.white.opacity(isFocused ? 1.0 : 0.82))
            .lineSpacing(14)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isFocused
                          ? accentColor.opacity(0.12)
                          : Color.white.opacity(isTitle ? 0.06 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isFocused ? accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

private struct ExternalLinkButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        TranquilFocusButton(action: onTap) { isFocused in
            HStack(spacing: 28) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(accentColor.opacity(isFocused ? 0.25 : 0.14))
                        .frame(width: 76, height: 76)
                    Image(systemName: icon)
                        .font(.system(size: 34))
                        .foregroundColor(accentColor)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 28))
                    .foregroundColor(isFocused ? accentColor : .white.opacity(0.3))
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 28)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(isFocused ? 0.08 : 0.04)))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(isFocused ? accentColor : Color.clear, lineWidth: 2.5))
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared SettingsCardView (used by AccountSettingsPage etc.)

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
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x1A1A1A)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isFocused ? theme.accentColor : Color.clear, lineWidth: 2.5))
            .shadow(color: isFocused ? theme.accentColor.opacity(0.3) : .clear, radius: 12)
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

#Preview { SettingsScreen() }
