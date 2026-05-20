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

    private var subscriptionProduct: Product? {
        storeKit.subscriptionProduct()
    }

    private var priceString: String {
        subscriptionProduct?.displayPrice ?? "$4.99"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1A0A2E), Color(hex: 0x0A0818), Color(hex: 0x0F0C29)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative background
            Circle()
                .fill(theme.accentColor.opacity(0.08))
                .frame(width: 600, height: 600)
                .offset(x: -200, y: -150)
            Circle()
                .fill(theme.accentColor.opacity(0.05))
                .frame(width: 400, height: 400)
                .offset(x: 300, y: 200)

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .tvFocusStyle()
                    Spacer()
                }
                .padding(.horizontal, TranquilTheme.standardPadding)
                .padding(.top, 40)

                Spacer()

                VStack(spacing: 40) {
                    // Logo & title
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(theme.accentColor.opacity(0.15))
                                .frame(width: 120, height: 120)
                            Image(systemName: "star.fill")
                                .font(.system(size: 56))
                                .foregroundColor(theme.accentColor)
                        }

                        Text("Unlock Premium")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)

                        Text("Experience unlimited tranquility")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    // Feature list
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "play.circle.fill", text: "Access all \(SceneService.shared.premiumScenes.count)+ premium scenes")
                        featureRow(icon: "headphones", text: "All audio-only ambient tracks")
                        featureRow(icon: "nosign", text: "No ads — pure relaxation")
                        featureRow(icon: "heart.fill", text: "Unlimited favorites")
                        featureRow(icon: "clock.fill", text: "Advanced sleep timer options")
                    }
                    .padding(32)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // Pricing & purchase buttons
                    VStack(spacing: 16) {
                        // Monthly subscription
                        Button {
                            Task { await purchaseSubscription() }
                        } label: {
                            HStack {
                                if isPurchasing {
                                    ProgressView().tint(.white)
                                } else {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Subscribe Monthly")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("\(priceString)/month · Cancel anytime")
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentColor, theme.accentColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: theme.accentColor.opacity(0.4), radius: 20)
                        }
                        .buttonStyle(.plain)
                        .tvFocusStyle()
                        .disabled(isPurchasing)

                        // Restore purchases
                        Button {
                            Task { await restorePurchases() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .tvFocusStyle()
                    }
                    .frame(maxWidth: 600)
                }
                .frame(maxWidth: 700)

                Spacer()

                Text("Payment charged to Apple ID account. Subscription auto-renews monthly.\nManage or cancel in Apple ID settings.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
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
    }

    @ViewBuilder
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(theme.accentColor)
                .frame(width: 32)
            Text(text)
                .font(.system(size: 20))
                .foregroundColor(.white)
            Spacer()
        }
    }

    private func purchaseSubscription() async {
        guard let product = subscriptionProduct else {
            // TODO: No product loaded — ensure StoreKit is configured
            purchaseError = "Product not available. Please check your App Store configuration."
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

#Preview { PaywallScreen() }
