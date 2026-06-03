import SwiftUI

struct TranquilTheme {
    // TV-native scale — cards fill the screen at a comfortable browsing size.
    static let homeCardScale: CGFloat = 1.4

    // MARK: - Card dimensions (base: 340×190 scene, 340×210 audio, 340×118 pack)

    static let sceneCardWidth: CGFloat  = 340 * homeCardScale   // 476
    static let sceneCardHeight: CGFloat = 190 * homeCardScale   // 266
    static let audioCardHeight: CGFloat = 210 * homeCardScale   // 294
    static let packCardHeight: CGFloat  = 170 * homeCardScale   // 238

    static var cardWidth: CGFloat  { sceneCardWidth }
    static var cardHeight: CGFloat { sceneCardHeight }

    static let cardCornerRadius: CGFloat  = 20
    static let cardScaleFocused: CGFloat  = 1.05
    static let focusBorderWidth: CGFloat  = 4
    /// Leading/trailing padding inside horizontal scroll rows so the focus
    /// scale-up never clips at the edge.
    static let focusEdgeInset: CGFloat = 24

    // MARK: - Layout spacing

    static let standardPadding: CGFloat        = 60
    static let contentVerticalPadding: CGFloat = 20
    static let headerHorizontalPadding: CGFloat = 80
    static let headerVerticalPadding: CGFloat   = 40
    static let sectionSpacing: CGFloat          = 48
    static let rowSpacing: CGFloat              = sectionSpacing
    static let sectionHeaderSpacing: CGFloat    = 22
    static let cardSpacing: CGFloat             = 32
    static let rowVerticalPadding: CGFloat      = 14
    static let focusRowExtraSpacing: CGFloat    = 24
    static let focusVisualOverflowMargin: CGFloat = 40
    static let sectionIconSize: CGFloat          = 36
    static let packsSectionIconSize: CGFloat     = 38
    static let sectionTitleToIconSpacing: CGFloat = 14

    // MARK: - In-card title insets

    static let cardTitleHorizontalPadding: CGFloat = 20
    static let cardTitleBottomPadding: CGFloat     = 24
    static let cardBadgeInset: CGFloat             = 16

    // MARK: - Caption below image

    static let cardCaptionSpacing: CGFloat = 10
    static let cardCaptionHeight: CGFloat  = 52

    // MARK: - Typography

    static let sectionTitleFont: Font        = .system(size: 42, weight: .heavy)
    static let cardTitleFont: Font           = .system(size: 28, weight: .heavy)
    static let cardCaptionFont: Font         = .system(size: 20, weight: .regular)
    static let cardTimeSuggestionFont: Font  = .system(size: 20, weight: .regular)
    static let packCardTitleFont: Font       = .system(size: 32, weight: .heavy)

    // MARK: - Row heights

    static let sceneRowHeight: CGFloat     = sceneCardHeight + cardCaptionSpacing + cardCaptionHeight + 40
    static let favoritesRowHeight: CGFloat = sceneRowHeight
    static let audioRowHeight: CGFloat     = audioCardHeight + cardCaptionSpacing + cardCaptionHeight + 40
    static let packsRowHeight: CGFloat     = packCardHeight  + cardCaptionSpacing + cardCaptionHeight + 40

    static func cardOuterWidth(for cardWidth: CGFloat) -> CGFloat {
        cardWidth * cardScaleFocused + focusBorderWidth * 2 + 8
    }

    static func cardOuterHeight(for cardHeight: CGFloat, includesCaption: Bool = true) -> CGFloat {
        let scaled = cardHeight * cardScaleFocused + focusBorderWidth * 2 + 8
        guard includesCaption else { return scaled }
        return scaled + cardCaptionSpacing + cardCaptionHeight
    }

    static func horizontalScrollTrailingInset(
        viewportWidth: CGFloat,
        cardOuterWidth: CGFloat,
        leadingInset: CGFloat = standardPadding
    ) -> CGFloat {
        max(standardPadding, viewportWidth - leadingInset - cardOuterWidth)
            + focusVisualOverflowMargin
    }
}
