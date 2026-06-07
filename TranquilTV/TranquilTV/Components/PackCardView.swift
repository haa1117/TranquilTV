import SwiftUI

struct PackCardView: View {
    let pack: PackDefinition
    let isPurchased: Bool
    var prefersDefaultFocus: Bool = false
    var focusNamespace: Namespace.ID? = nil
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            PackCardLabel(pack: pack, isPurchased: isPurchased)
        }
        .tranquilTVButton()
        .modifier(DefaultFocusModifier(isPreferred: prefersDefaultFocus, namespace: focusNamespace))
        .frame(
            width: TranquilTheme.cardOuterWidth(for: TranquilTheme.sceneCardWidth),
            height: TranquilTheme.cardOuterHeight(for: TranquilTheme.packCardHeight)
        )
    }
}

private struct PackCardLabel: View {
    let pack: PackDefinition
    let isPurchased: Bool

    @Environment(\.isFocused) private var isFocused
    @ObservedObject private var settings = SettingsService.shared
    @ObservedObject private var storeKit = StoreKitService.shared
    private var theme: AppTheme { settings.currentTheme }

    private var previewAssets: [String] { pack.previewImageAssets }

    private var captionText: String {
        pack.categories.map(\.name).joined(separator: " · ")
    }

    private var livePriceString: String {
        if let pid = pack.productId, let product = storeKit.product(id: pid) {
            return product.displayPrice
        }
        return pack.priceString
    }

    var body: some View {
        VStack(alignment: .center, spacing: TranquilTheme.cardCaptionSpacing) {
            ZStack {
                packImageMosaic
                    .frame(width: TranquilTheme.sceneCardWidth, height: TranquilTheme.packCardHeight)
                    .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.72), .black.opacity(0.25), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )

                VStack {
                    HStack {
                        if isPurchased || pack.isFree {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                Text("Owned")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.85))
                            .clipShape(Capsule())
                        } else if !pack.isFree {
                            Text(livePriceString)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.65))
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, TranquilTheme.cardBadgeInset)
                    .padding(.top, 8)

                    Spacer()

                    Text(pack.name)
                        .font(TranquilTheme.packCardTitleFont)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .padding(.horizontal, TranquilTheme.cardTitleHorizontalPadding)
                        .padding(.bottom, 10)
                }
            }
            .frame(width: TranquilTheme.sceneCardWidth, height: TranquilTheme.packCardHeight)
            .clipShape(RoundedRectangle(cornerRadius: TranquilTheme.cardCornerRadius))
            .cardFocusChrome(
                isFocused: isFocused,
                cornerRadius: TranquilTheme.cardCornerRadius,
                accentColor: theme.accentColor
            )

            Text(captionText)
                .font(TranquilTheme.cardCaptionFont)
                .foregroundColor(.white.opacity(isFocused ? 0.82 : 0.65))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: TranquilTheme.sceneCardWidth,
                       height: TranquilTheme.cardCaptionHeight,
                       alignment: .top)
        }
    }

    @ViewBuilder
    private var packImageMosaic: some View {
        let assets = previewAssets
        if assets.isEmpty {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x2B2B45), Color(hex: 0x3C3C5A)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else if assets.count == 1 {
            Image(assets[0])
                .resizable()
                .scaledToFill()
        } else {
            let slotWidth = (TranquilTheme.sceneCardWidth - 2 * 2) / 3   // 2pt gaps between 3 slots
            HStack(spacing: 2) {
                ForEach(Array(assets.prefix(3).enumerated()), id: \.offset) { _, asset in
                    Image(asset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: slotWidth, height: TranquilTheme.packCardHeight)
                        .clipped()
                }
            }
        }
    }
}
