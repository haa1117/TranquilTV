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
    case buyBundle
    case restore
}

private enum DialogFocusID: Hashable {
    case cancel
    case buyPremium
    case buyCategory
    case buyBundle
    case restore
}

private enum DialogButtonStyle {
    case primary, accent, secondary, muted
}

struct PremiumUnlockDialog: View {
    let content: PremiumUnlockContent
    let onAction: (PremiumUnlockAction) -> Void

    @ObservedObject private var settings = SettingsService.shared
    @StateObject private var storeKit = StoreKitService.shared
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var purchaseError: String?
    @State private var showError = false
    @FocusState private var focusedAction: DialogFocusID?
    @Namespace private var dialogFocusScope

    private var theme: AppTheme { settings.currentTheme }

    // MARK: - Computed helpers

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
        case .scene(let scene):
            let bundle = IAPProductCatalog.packContainingSceneCategory(scene.category)
            let hasOwn = IAPProductCatalog.oneTimeProductForSceneCategory(scene.category) != nil
            if !hasOwn, let bundle {
                return "Unlock all \(bundle.categories.count) scenes in \"\(bundle.name)\" with a one-time bundle purchase, or subscribe for full access to everything."
            }
            return "This scene requires premium access. Subscribe for unlimited scenes, or buy this category once to own it forever."
        case .audio:
            return "This sound requires premium access. Subscribe for unlimited audio, or buy this track once to own it forever."
        case .pack(let pack):
            return "Unlock all \(pack.categories.count) scenes in \"\(pack.name)\" with a one-time purchase, or subscribe for full access to everything."
        }
    }

    /// Product ID for the single-item (scene / audio / pack) one-time purchase.
    private var oneTimeProductId: String? {
        switch content {
        case .scene(let scene):
            return IAPProductCatalog.oneTimeProductForSceneCategory(scene.category)
        case .audio(let item):
            return IAPProductCatalog.oneTimeProductForAudioTitle(item.title)
        case .pack(let pack):
            return pack.productId
        }
    }

    /// Bundle that contains this scene (nil for audio/pack content).
    private var containingBundle: PackDefinition? {
        guard case .scene(let scene) = content else { return nil }
        return IAPProductCatalog.packContainingSceneCategory(scene.category)
    }

    private var subscriptionPrice: String {
        storeKit.subscriptionProduct()?.displayPrice ?? IAPProductCatalog.fallbackPrice(for: IAPProductCatalog.subscriptionProductId)
    }

    private var categoryPrice: String {
        if let pid = oneTimeProductId, let product = storeKit.product(id: pid) {
            return product.displayPrice
        }
        if case .pack(let pack) = content { return pack.priceString }
        // Fallback: look up the individual scene/audio product price from the catalog
        if let pid = oneTimeProductId {
            return IAPProductCatalog.fallbackPrice(for: pid)
        }
        return ""
    }

    private var bundlePrice: String {
        guard let bundle = containingBundle else { return "" }
        if let pid = bundle.productId, let product = storeKit.product(id: pid) {
            return product.displayPrice
        }
        return bundle.priceString
    }

    private var buyCategoryTitle: String {
        switch content {
        case .pack: return "Buy Bundle"
        case .scene(let scene): return "Buy \(scene.name)"
        case .audio(let item): return "Buy \(item.title)"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                headerRow

                previewImage
                    .frame(width: 640, height: 340)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: theme.accentColor.opacity(0.25), radius: 24, y: 12)

                VStack(spacing: 14) {
                    Text(itemTitle)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(theme.accentColor.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(bodyMessage)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 780)
                        .padding(.top, 4)
                }

                if isPurchasing || isRestoring {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.vertical, 8)
                } else {
                    actionButtons
                }
            }
            .padding(.horizontal, 64)
            .padding(.vertical, 52)
            .background(
                RoundedRectangle(cornerRadius: 32)
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
                RoundedRectangle(cornerRadius: 32)
                    .stroke(theme.accentColor.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.45), radius: 40, y: 20)
            .frame(maxWidth: 1200)
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
        HStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(theme.accentColor)
            Text(headline)
                .font(.system(size: 36, weight: .bold))
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
            let slotWidth = (640.0 - 3 * 2) / 3
            HStack(spacing: 2) {
                ForEach(Array(assets.prefix(3).enumerated()), id: \.offset) { _, asset in
                    Image(asset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: slotWidth, height: 340)
                        .clipped()
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

    // MARK: - Action buttons
    //
    // Layout rule:
    //   Row 1: all main purchase CTAs (up to 3) — no Cancel here
    //   Row 2: Restore Purchases  |  Cancel
    //
    // Bundle-only scene:  Buy Bundle  |  Subscribe
    // Scene/Audio w IAP:  Subscribe   |  Buy Item  |  Buy Bundle (if in bundle)
    // Pack:               Buy Pack    |  Subscribe

    @ViewBuilder
    private var actionButtons: some View {
        let hasOwnIAP = oneTimeProductId != nil && !(content.isPack)
        let bundleOnly = !hasOwnIAP && containingBundle != nil

        VStack(spacing: 16) {
            // ── Row 1: purchase CTAs (no Cancel) ────────────────────────────
            HStack(spacing: 16) {
                if bundleOnly, let bundle = containingBundle {
                    dialogButton(
                        focusId: .buyBundle,
                        title: "Buy \(bundle.name)",
                        subtitle: bundlePrice.isEmpty ? nil : bundlePrice,
                        icon: "bag.fill",
                        style: .primary
                    ) { Task { await purchaseBundle(bundle) } }

                    dialogButton(
                        focusId: .buyPremium,
                        title: "Subscribe to Premium",
                        subtitle: "\(subscriptionPrice)/mo",
                        icon: "star.fill",
                        style: .accent
                    ) { Task { await purchaseSubscription() } }

                } else if case .pack = content {
                    dialogButton(
                        focusId: .buyCategory,
                        title: buyCategoryTitle,
                        subtitle: categoryPrice,
                        icon: "bag.fill",
                        style: .primary
                    ) { Task { await purchaseCategory() } }

                    dialogButton(
                        focusId: .buyPremium,
                        title: "Subscribe to Premium",
                        subtitle: "\(subscriptionPrice)/mo",
                        icon: "star.fill",
                        style: .accent
                    ) { Task { await purchaseSubscription() } }

                } else {
                    // Scene/audio with own IAP — optionally also in a bundle
                    dialogButton(
                        focusId: .buyPremium,
                        title: "Subscribe to Premium",
                        subtitle: "\(subscriptionPrice)/mo",
                        icon: "star.fill",
                        style: .accent
                    ) { Task { await purchaseSubscription() } }

                    if oneTimeProductId != nil {
                        dialogButton(
                            focusId: .buyCategory,
                            title: buyCategoryTitle,
                            subtitle: categoryPrice,
                            icon: "cart.fill",
                            style: .primary
                        ) { Task { await purchaseCategory() } }
                    }

                    if let bundle = containingBundle {
                        dialogButton(
                            focusId: .buyBundle,
                            title: "Buy \(bundle.name)",
                            subtitle: bundlePrice.isEmpty ? nil : bundlePrice,
                            icon: "square.stack.fill",
                            style: .accent
                        ) { Task { await purchaseBundle(bundle) } }
                    }
                }
            }

            // ── Row 2: Restore | Cancel ──────────────────────────────────────
            HStack(spacing: 16) {
                dialogButton(
                    focusId: .restore,
                    title: "Restore Purchases",
                    subtitle: nil,
                    icon: "arrow.clockwise",
                    style: .muted
                ) { Task { await restorePurchases() } }

                dialogButton(
                    focusId: .cancel,
                    title: "Cancel",
                    subtitle: nil,
                    icon: "xmark",
                    style: .secondary
                ) { onAction(.cancel) }
            }
        }
    }

    @ViewBuilder
    private func dialogButton(
        focusId: DialogFocusID,
        title: String,
        subtitle: String?,
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

    // MARK: - Purchase actions

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

    private func purchaseBundle(_ bundle: PackDefinition) async {
        guard let productId = bundle.productId,
              let product = storeKit.product(id: productId) else {
            purchaseError = "This bundle is not available for purchase yet."
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
                onAction(.buyBundle)
            }
        } catch {
            purchaseError = error.localizedDescription
            showError = true
        }
    }

    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }
        await storeKit.restorePurchases()
        onAction(.restore)
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

// MARK: - Button label

private struct DialogButtonLabel: View {
    let title: String
    let subtitle: String?
    let icon: String
    let style: DialogButtonStyle
    let theme: AppTheme

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .opacity(0.85)
            }
        }
        .foregroundColor(foregroundColor)
        .frame(minWidth: 220, minHeight: 108)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
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
        case .secondary, .muted: return .white.opacity(style == .muted ? 0.55 : 0.85)
        case .primary, .accent: return .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .muted:
            return Color.white.opacity(isFocused ? 0.12 : 0.05)
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
        case .muted: return Color.white.opacity(0.12)
        case .secondary: return Color.white.opacity(0.25)
        case .primary: return theme.premiumBadgeColor.opacity(0.6)
        case .accent: return theme.accentColor.opacity(0.55)
        }
    }
}

// MARK: - IAPProductCatalog bundle lookup

extension IAPProductCatalog {
    /// Returns the paid PackDefinition that contains this scene category, if any.
    static func packContainingSceneCategory(_ sceneCategory: String) -> PackDefinition? {
        for pack in PackService.allPacks {
            if pack.isFree || pack.productId == nil { continue }
            if pack.categories.contains(where: { $0.sceneCategory == sceneCategory }) {
                return pack
            }
        }
        return nil
    }
}

// MARK: - Helpers

private extension PremiumUnlockContent {
    var isPack: Bool {
        if case .pack = self { return true }
        return false
    }
}
