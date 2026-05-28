import SwiftUI

/// Pick a category/scene from a pack — parity with Android bundle category selection.
struct BundlePickerScreen: View {
    let pack: PackDefinition
    let onSelectScene: (Scene) -> Void
    let onDismiss: () -> Void

    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    FocusableCircleButton(icon: "xmark", size: 52) { onDismiss() }
                    Spacer()
                    VStack(spacing: 4) {
                        Text(pack.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Text("Choose a scene to play")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    Spacer()
                    Color.clear.frame(width: 52)
                }
                .padding(.horizontal, TranquilTheme.standardPadding)
                .padding(.vertical, 28)

                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: TranquilTheme.cardOuterWidth(for: TranquilTheme.sceneCardWidth)), spacing: TranquilTheme.cardSpacing)],
                        spacing: TranquilTheme.sectionSpacing
                    ) {
                        ForEach(accessibleCategories, id: \.id) { category in
                            if let scene = scene(for: category) {
                                categoryCard(category: category, scene: scene)
                            }
                        }
                    }
                    .padding(.horizontal, TranquilTheme.standardPadding)
                    .padding(.bottom, 60)
                }
            }
        }
    }

    private var accessibleCategories: [PackCategory] {
        if pack.isFree { return pack.categories }
        if settings.isPremium { return pack.categories }
        if settings.isPackPurchased(pack) {
            let selected = settings.selectedCategories(for: pack.id)
            if selected.isEmpty { return pack.categories }
            return pack.categories.filter { selected.contains($0.id) }
        }
        return []
    }

    private func scene(for category: PackCategory) -> Scene? {
        SceneService.shared.allScenes.first { $0.category == category.sceneCategory }
    }

    @ViewBuilder
    private func categoryCard(category: PackCategory, scene: Scene) -> some View {
        Button(action: { onSelectScene(scene) }) {
            CategoryCardLabel(category: category, scene: scene, theme: theme)
        }
        .tranquilTVButton()
        .frame(
            width: TranquilTheme.cardOuterWidth(for: TranquilTheme.sceneCardWidth),
            height: TranquilTheme.cardOuterHeight(for: TranquilTheme.sceneCardHeight)
        )
    }
}

private struct CategoryCardLabel: View {
    let category: PackCategory
    let scene: Scene
    let theme: AppTheme

    @Environment(\.isFocused) private var isFocused

    private var imageAsset: String? {
        scene.localImageAsset ?? CategoryAssets.imageName(for: category.sceneCategory)
    }

    private var captionText: String {
        if !scene.description.isEmpty { return scene.description }
        return scene.name
    }

    var body: some View {
        VStack(alignment: .center, spacing: TranquilTheme.cardCaptionSpacing) {
            ZStack {
                Group {
                    if let asset = imageAsset {
                        Image(asset)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(theme.accentColor.opacity(0.25))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 48 * TranquilTheme.homeCardScale))
                                    .foregroundColor(theme.accentColor)
                            )
                    }
                }
                .frame(width: TranquilTheme.sceneCardWidth, height: TranquilTheme.sceneCardHeight)
                .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.65), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )

                VStack {
                    Spacer()
                    Text(category.name)
                        .font(TranquilTheme.cardTitleFont)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .padding(.horizontal, TranquilTheme.cardTitleHorizontalPadding)
                        .padding(.bottom, TranquilTheme.cardTitleBottomPadding)
                }
            }
            .frame(width: TranquilTheme.sceneCardWidth, height: TranquilTheme.sceneCardHeight)
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
}
