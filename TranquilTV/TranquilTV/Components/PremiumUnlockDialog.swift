import SwiftUI
import StoreKit

enum PremiumUnlockContent: Identifiable {
    case scene(Scene)
    case audio(AudioOnlyItem)
    case pack(PackDefinition)

    var id: String {
        switch self {
        case .scene(let scene): return "scene-\(scene.id)"
        case .audio(let item): return "audio-\(item.id)"
        case .pack(let pack): return "pack-\(pack.id)"
        }
    }
}

enum PremiumUnlockAction {
    case cancel
    case buyPremium
    case buyCategory
}

struct PremiumUnlockDialog: View {
    let content: PremiumUnlockContent
    let onAction: (PremiumUnlockAction) -> Void

    @ObservedObject private var settings = SettingsService.shared
    @StateObject private var storeKit = StoreKitService.shared
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showError = false
    @Namespace private var dialogFocusScope

    private var theme: AppTheme { settings.currentTheme }

    private var headline: String {
        switch content {
        case .scene: return "Premium Scene"
        case .audio: return "Premium Audio"
        case .pack: return "Premium Bundle"
        }
    }

    private var itemTitle: String {
        switch content {
        case .scene(let scene): return scene.name
        case .audio(let item): return item.title
        case .pack(let pack): return pack.name
        }
    }

    private var subtitle: String {
        switch content {
        case .scene(let scene): return scene.category
        case .audio(let item): return item.category
        case .pack(let pack):
            return pack.categories.map(\.name).joined(separator: " · ")
        }
    }

    private var bodyMessage: String {
        switch content {
        case .scene:
            return "This scene requires premium access. Subscribe for unlimited scenes, or buy this category once to own it forever."
        case .audio:
            return "This sound requires premium access. Subscribe for unlimited audio, or buy this track once to own it forever."
        case .pack(let pack):
            return "Unlock all \(pack.categories.count) scenes in \"\(pack.name)\" with a bundle purchase, or subscribe for full access to everything."
        }
    }

    private var oneTimeProductId: String? {
        switch content {
        case .scene(let scene):
            return settings.oneTimeProductForSceneCategory(scene.category)
        case .audio(let item):
            return settings.oneTimeProductForAudioTitle(item.title)
        case .pack(let pack):
            return pack.productId
        }
    }

    private var subscriptionPrice: String {
        storeKit.subscriptionProduct()?.displayPrice ?? "$4.99"
    }

    private var categoryPrice: String {
        guard let pid = oneTimeProductId, let product = storeKit.product(id: pid) else {
            switch content {
            case .pack(let pack): return pack.priceString
            default: return "$1.99"
            }
        }
        return product.displayPrice
    }

    private var buyCategoryTitle: String {
        switch content {
        case .pack: return "Buy Bundle"
        case .scene, .audio: return "Buy Category"
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                headerRow

                previewImage
                    .frame(width: 520, height: 292)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: theme.accentColor.opacity(0.25), radius: 24, y: 12)

                VStack(spacing: 10) {
                    Text(itemTitle)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(theme.accentColor.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(bodyMessage)
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 620)
                        .padding(.top, 4)
                }

                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.vertical, 8)
                } else {
                    actionButtons
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.gradientColors.first ?? Color(hex: 0x1A1A2E),
                                theme.gradientColors.last ?? Color(hex: 0x16213E),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(theme.accentColor.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.45), radius: 40, y: 20)
            .frame(maxWidth: 760)
            .focusScope(dialogFocusScope)
        }
        .onExitCommand { onAction(.cancel) }
        .onAppear { logDialogView() }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseError ?? "An error occurred")
        }
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(theme.accentColor)
            Text(headline)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private var previewImage: some View {
        switch content {
        case .scene(let scene):
            categoryImage(assetName: scene.localImageAsset, fallbackIcon: "photo.tv")
        case .audio(let item):
            categoryImage(assetName: item.localImageAsset, fallbackIcon: "headphones")
        case .pack(let pack):
            packMosaic(assets: pack.previewImageAssets)
        }
    }

    @ViewBuilder
    private func categoryImage(assetName: String?, fallbackIcon: String) -> some View {
        ZStack {
            if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color(hex: 0x2B2B45), Color(hex: 0x3C3C5A)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: fallbackIcon)
                    .font(.system(size: 56))
                    .foregroundColor(.white.opacity(0.35))
            }

            LinearGradient(
                colors: [.black.opacity(0.55), .clear],
                startPoint: .bottom,
                endPoint: .center
            )
        }
    }

    @ViewBuilder
    private func packMosaic(assets: [String]) -> some View {
        if assets.isEmpty {
            categoryImage(assetName: nil, fallbackIcon: "square.stack.3d.up.fill")
        } else if assets.count == 1 {
            categoryImage(assetName: assets[0], fallbackIcon: "square.stack.3d.up.fill")
        } else {
            HStack(spacing: 3) {
                ForEach(Array(assets.prefix(3).enumerated()), id: \.offset) { _, asset in
                    Image(asset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 520 / 3 - 2)
                }
            }
            .overlay {
                LinearGradient(
                    colors: [.black.opacity(0.45), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            dialogButton(
                title: "Cancel",
                icon: "xmark",
                style: .secondary,
                isDefault: false
            ) {
                onAction(.cancel)
            }

            dialogButton(
                title: "Buy Premium",
                subtitle: "\(subscriptionPrice)/mo",
                icon: "star.fill",
                style: .primary,
                isDefault: true
            ) {
                Task { await purchaseSubscription() }
            }

            if oneTimeProductId != nil {
                dialogButton(
                    title: buyCategoryTitle,
                    subtitle: categoryPrice,
                    icon: content.isPack ? "bag.fill" : "cart.fill",
                    style: .accent,
                    isDefault: false
                ) {
                    Task { await purchaseCategory() }
                }
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func dialogButton(
        focusId: DialogFocusID,
        title: String,
        subtitle: String? = nil,
        icon: String,
        style: DialogButtonStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            DialogButtonLabel(
                title: title,
                subtitle: subtitle,
                icon: icon,
                style: style,
                theme: theme
            )
        }
        .tranquilTVButton()
        .focused($focusedAction, equals: focusId)
    }

    // MARK: - Purchases

    private func purchaseSubscription() async {
        guard let product = storeKit.subscriptionProduct() else {
            purchaseError = "Premium subscription is not available yet."
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
                onAction(.buyPremium)
            }
        } catch {
            purchaseError = error.localizedDescription
            showError = true
        }
    }

    private func purchaseCategory() async {
        guard let productId = oneTimeProductId,
              let product = storeKit.product(id: productId) else {
            purchaseError = "This item is not available for purchase yet."
            showError = true
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        AnalyticsService.logPurchaseAttempt(productId: productId)
        do {
            let success = try await storeKit.purchase(product)
            if success {
                AnalyticsService.logPurchaseSuccess(productId: productId)
                onAction(.buyCategory)
            }
        } catch {
            purchaseError = error.localizedDescription
            showError = true
        }
    }

    private func logDialogView() {
        switch content {
        case .scene(let scene):
            AnalyticsService.logPaywallView(reason: "locked_scene")
            AnalyticsService.logLockedSceneTapped(
                sceneId: scene.id,
                sceneName: scene.name,
                category: scene.category,
                section: "home"
            )
        case .audio(let item):
            AnalyticsService.logPaywallView(reason: "locked_audio")
            AnalyticsService.logAudioOnlyTapped(
                itemId: item.id,
                title: item.title,
                category: item.category,
                isFree: item.isFree,
                section: "home_locked"
            )
        case .pack(let pack):
            AnalyticsService.logPaywallView(reason: "locked_pack")
            AnalyticsService.logPackTapped(packId: pack.id, packName: pack.name)
        }
    }
}

private struct DialogButtonLabel: View {
    let title: String
    let subtitle: String?
    let icon: String
    let style: DialogButtonStyle
    let theme: AppTheme

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .opacity(0.85)
            }
        }
        .foregroundColor(foregroundColor)
        .frame(minWidth: 180, minHeight: 88)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: isFocused ? 3 : 1.5)
        )
        .scaleEffect(isFocused ? 1.06 : 1.0)
        .shadow(color: isFocused ? theme.accentColor.opacity(0.35) : .clear, radius: 16)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    private var foregroundColor: Color {
        switch style {
        case .secondary: return .white.opacity(0.85)
        case .primary, .accent: return .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .secondary:
            return Color.white.opacity(isFocused ? 0.18 : 0.1)
        case .primary:
            return theme.premiumBadgeColor.opacity(isFocused ? 0.95 : 0.82)
        case .accent:
            return theme.accentColor.opacity(isFocused ? 0.95 : 0.78)
        }
    }

    private var borderColor: Color {
        if isFocused { return theme.accentColor.opacity(0.95) }
        switch style {
        case .secondary: return Color.white.opacity(0.25)
        case .primary: return theme.premiumBadgeColor.opacity(0.6)
        case .accent: return theme.accentColor.opacity(0.55)
        }
    }
}

private struct RestoreButtonLabel: View {
    let isRestoring: Bool

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        HStack(spacing: 6) {
            if isRestoring {
                ProgressView().tint(.white.opacity(0.6)).scaleEffect(0.8)
            } else {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
            }
            Text(isRestoring ? "Restoring…" : "Restore Purchases")
                .font(.system(size: 14))
        }
        .foregroundColor(.white.opacity(isFocused ? 0.85 : 0.55))
        .underline(!isRestoring)
        .frame(maxWidth: .infinity, minHeight: 44)
        .tvFocusStyle(isFocused: isFocused)
    }
}

private extension PremiumUnlockContent {
    var isPack: Bool {
        if case .pack = self { return true }
        return false
    }
}
