import SwiftUI

struct AccountSettingsPage: View {
    @ObservedObject private var settings = SettingsService.shared
    @ObservedObject private var storeKit = StoreKitService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var restoreMessage: String?

    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                settingsNavBar(title: "Account")

                ScrollView {
                    VStack(spacing: 16) {
                        SettingsCardView(
                            icon: "arrow.clockwise.circle.fill",
                            title: "Restore Purchases",
                            subtitle: "Sync subscriptions and one-time unlocks"
                        ) {
                            Task {
                                await storeKit.restorePurchases()
                                restoreMessage = settings.isPremium
                                    ? "Purchases restored."
                                    : "No active purchases found."
                            }
                        }

                        SettingsCardView(
                            icon: "crown.fill",
                            title: "Upgrade to Premium",
                            subtitle: settings.isPremium ? "You have Premium" : "Unlock all scenes and packs"
                        ) {
                            showPaywall = true
                        }
                    }
                    .padding(.horizontal, TranquilTheme.standardPadding)
                    .padding(.bottom, 60)
                }

                if let restoreMessage {
                    Text(restoreMessage)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 24)
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallScreen()
        }
        .onAppear {
            AnalyticsService.logScreenView("account_settings_screen")
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

#Preview { AccountSettingsPage() }
