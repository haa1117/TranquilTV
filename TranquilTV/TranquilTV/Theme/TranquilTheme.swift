import SwiftUI

struct TranquilTheme {
    /// Matches Android TV `_kHomeCardScale = 0.8`.
    static let homeCardScale: CGFloat = 0.8

    // MARK: - Card dimensions (Android: 340×190 scene, 340×210 audio, 340×118 pack)

    static let sceneCardWidth: CGFloat = 340 * homeCardScale
    static let sceneCardHeight: CGFloat = 190 * homeCardScale
    static let audioCardHeight: CGFloat = 210 * homeCardScale
    static let packCardHeight: CGFloat = 118 * homeCardScale

    static var cardWidth: CGFloat { sceneCardWidth }
    static var cardHeight: CGFloat { sceneCardHeight }

    static let cardCornerRadius: CGFloat = 16 * homeCardScale
    static let cardScaleFocused: CGFloat = 1.05
    static let focusBorderWidth: CGFloat = 3 * homeCardScale

    // MARK: - Layout spacing (Android home_screen.dart)

    static let standardPadding: CGFloat = 32
    static let contentVerticalPadding: CGFloat = 12
    static let headerHorizontalPadding: CGFloat = 48
    static let headerVerticalPadding: CGFloat = 32
    static let sectionSpacing: CGFloat = 32
    static let rowSpacing: CGFloat = sectionSpacing
    static let sectionHeaderSpacing: CGFloat = 18
    static let cardSpacing: CGFloat = 20
    static let rowVerticalPadding: CGFloat = 10
    static let focusRowExtraSpacing: CGFloat = 20
    /// Extra trailing scroll room so the last card is fully visible.
    static let focusVisualOverflowMargin: CGFloat = 32
    static let sectionIconSize: CGFloat = 26
    static let packsSectionIconSize: CGFloat = 28
    static let sectionTitleToIconSpacing: CGFloat = 10

    // MARK: - In-card title insets

    static let cardTitleHorizontalPadding: CGFloat = 14 * homeCardScale
    static let cardTitleBottomPadding: CGFloat = 20 * homeCardScale
    static let cardBadgeInset: CGFloat = 12 * homeCardScale

    // MARK: - Caption below image (tvOS layout)

    static let cardCaptionSpacing: CGFloat = 6 * homeCardScale
    static let cardCaptionHeight: CGFloat = 34

    // MARK: - Typography

    static let sectionTitleFont: Font = .system(size: 28, weight: .heavy)
    static let cardTitleFont: Font = .system(size: 18, weight: .heavy)
    static let cardCaptionFont: Font = .system(size: 13, weight: .regular)
    static let cardTimeSuggestionFont: Font = .system(size: 13, weight: .regular)
    static let packCardTitleFont: Font = .system(size: 22, weight: .heavy)

    // MARK: - Row heights (Android SizedBox heights × scale)

    static let sceneRowHeight: CGFloat = 260 * homeCardScale
    static let favoritesRowHeight: CGFloat = 230 * homeCardScale
    static let audioRowHeight: CGFloat = 185 * homeCardScale
    static let packsRowHeight: CGFloat = 195 * homeCardScale

    static func cardOuterWidth(for cardWidth: CGFloat) -> CGFloat {
        cardWidth * cardScaleFocused + focusBorderWidth * 2 + 8
    }

    static func cardOuterHeight(for cardHeight: CGFloat, includesCaption: Bool = true) -> CGFloat {
        let scaled = cardHeight * cardScaleFocused + focusBorderWidth * 2 + 8
        guard includesCaption else { return scaled }
        return scaled + cardCaptionSpacing + cardCaptionHeight
    }

    /// Trailing inset so the last card can scroll to the same leading position as the
    /// first card. tvOS native focus scrolling aligns focused cards at the leading inset,
    /// so the scroll extent must reach: lastCard.leadingEdge - leadingInset.
    static func horizontalScrollTrailingInset(
        viewportWidth: CGFloat,
        cardOuterWidth: CGFloat,
        leadingInset: CGFloat = standardPadding
    ) -> CGFloat {
        max(standardPadding, viewportWidth - leadingInset - cardOuterWidth)
            + focusVisualOverflowMargin
    }
}
