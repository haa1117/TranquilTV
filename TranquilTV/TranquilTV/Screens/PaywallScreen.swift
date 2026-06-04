import SwiftUI
import StoreKit

struct PaywallScreen: View {
    @ObservedObject private var settings = SettingsService.shared
    @StateObject private var storeKit = StoreKitService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showError = false

    private var theme: AppTheme { settings.currentTheme }
    private var subscriptionProduct: Product? { storeKit.subscriptionProduct() }
    private var priceString: String { subscriptionProduct?.displayPrice ?? "$4.99" }

    @Namespace private var focusNamespace

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0A0515), Color(hex: 0x0D0A25), Color(hex: 0x080615)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(theme.accentColor.opacity(0.10))
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: geo.size.width * 0.55, y: -geo.size.height * 0.15)
                    .blur(radius: 120)
                Circle()
                    .fill(theme.accentColor.opacity(0.06))
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: -geo.size.width * 0.05, y: geo.size.height * 0.55)
                    .blur(radius: 100)
            }
            .ignoresSafeArea()

            // Single layout tree so the focus engine can navigate between all buttons.
            VStack(spacing: 0) {
                // ── TOP: back button row (its own focus section) ──────────
                HStack {
                    FocusableCircleButton(icon: "chevron.left", size: 52) { dismiss() }
                    Spacer()
                }
                .padding(.leading, 60)
                .padding(.top, 48)
                .padding(.bottom, 20)
                .focusSection()

                // ── MAIN: two-column content (its own focus section) ──────
                HStack(spacing: 0) {
                    // LEFT — Identity + value prop (non-interactive, no focusable items)
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(theme.accentColor.opacity(0.15))
                                .frame(width: 140, height: 140)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 68))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.accentColor, theme.premiumBadgeColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.bottom, 40)

                        Text("Unlock Premium")
                            .font(.system(size: 68, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .padding(.bottom, 16)

                        Text("Experience unlimited tranquility.\nNo limits. No ads. Pure peace.")
                            .font(.system(size: 30, weight: .light))
                            .foregroundColor(.white.opacity(0.65))
                            .lineSpacing(8)
                            .padding(.bottom, 52)

                        VStack(alignment: .leading, spacing: 24) {
                            featureRow(icon: "play.circle.fill",       text: "All \(SceneService.shared.premiumScenes.count)+ premium scenes")
                            featureRow(icon: "headphones",              text: "All ambient audio tracks")
                            featureRow(icon: "nosign",                  text: "Zero ads — pure relaxation")
                            featureRow(icon: "heart.fill",              text: "Unlimited favourites")
                            featureRow(icon: "arrow.clockwise.circle", text: "Cancel anytime")
                        }

                        Spacer()

                        Text("Payment charged to Apple ID. Manage in Apple ID settings.")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.bottom, 40)
                    }
                    .padding(.leading, 100)
                    .padding(.trailing, 60)
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 1)
                        .padding(.vertical, 40)

                    // RIGHT — Purchase card (two focusable buttons)
                    VStack(spacing: 40) {
                        VStack(spacing: 20) {
                            Text("Monthly Plan")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white.opacity(0.55))

                            Text(priceString)
                                .font(.system(size: 80, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, theme.accentColor.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("per month")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 52)
                        .background(RoundedRectangle(cornerRadius: 32).fill(Color.white.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 32).stroke(theme.accentColor.opacity(0.3), lineWidth: 1.5))

                        // Subscribe — gets default focus on open
                        TranquilFocusButton(
                            action: { Task { await purchaseSubscription() } },
                            prefersDefaultFocus: true,
                            focusNamespace: focusNamespace
                        ) { isFocused in
                            SubscribeButtonLabel(isPurchasing: isPurchasing, priceString: priceString,
                                                theme: theme, isFocused: isFocused)
                        }
                        .disabled(isPurchasing)

                        TranquilFocusButton(action: {
                            Task { await restorePurchases() }
                        }) { isFocused in
                            RestorePurchasesLabel(isFocused: isFocused, theme: theme)
                        }
                        .disabled(isPurchasing)
                    }
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 80)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: .infinity)
                .focusSection()
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseError ?? "An error occurred")
        }
        .onAppear {
            AnalyticsService.logPaywallView(reason: "paywall_screen")
        }
        .onExitCommand { dismiss() }
    }

    @ViewBuilder
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(theme.accentColor)
                .frame(width: 40)
            Text(text)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
    }

    private func purchaseSubscription() async {
        guard let product = subscriptionProduct else {
            purchaseError = "Product not available. Please try again later."
            showError = true
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        AnalyticsService.logPurchaseAttempt(productId: StoreKitService.subscriptionProductId)
        do {
            let success = try await storeKit.purchase(product)
            if success {
                AnalyticsService.logPurchaseSuccess(productId: StoreKitService.subscriptionProductId)
                dismiss()
            }
        } catch {
            purchaseError = error.localizedDescription
            showError = true
        }
    }

    private func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        await storeKit.restorePurchases()
        if settings.isPremium { dismiss() }
    }
}

private struct SubscribeButtonLabel: View {
    let isPurchasing: Bool
    let priceString: String
    let theme: AppTheme
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 16) {
            if isPurchasing {
                ProgressView().tint(.white).scaleEffect(1.2)
                Text("Processing…")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "star.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                Text("Subscribe — \(priceString)/mo")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            LinearGradient(
                colors: [
                    theme.accentColor.opacity(isFocused ? 1.0 : 0.9),
                    theme.premiumBadgeColor.opacity(isFocused ? 1.0 : 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(isFocused ? 0.6 : 0), lineWidth: 2.5)
        )
        .shadow(color: theme.accentColor.opacity(isFocused ? 0.6 : 0.25), radius: isFocused ? 28 : 16)
        .scaleEffect(isFocused ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

private struct RestorePurchasesLabel: View {
    let isFocused: Bool
    let theme: AppTheme

    var body: some View {
        Text("Restore Purchases")
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(isFocused ? .white : .white.opacity(0.45))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isFocused ? Color.white.opacity(0.10) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isFocused ? theme.accentColor.opacity(0.6) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

#Preview { PaywallScreen() }
