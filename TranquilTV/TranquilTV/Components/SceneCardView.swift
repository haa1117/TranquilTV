import SwiftUI

struct SceneCardView: View {
    let scene: Scene
    let isLocked: Bool
    var timeSuggestion: String? = nil
    var prefersDefaultFocus: Bool = false
    var focusNamespace: Namespace.ID? = nil
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            SceneCardLabel(scene: scene, isLocked: isLocked, timeSuggestion: timeSuggestion)
        }
        .tranquilTVButton()
        .modifier(DefaultFocusModifier(isPreferred: prefersDefaultFocus, namespace: focusNamespace))
        .frame(
            width: TranquilTheme.cardOuterWidth(for: TranquilTheme.sceneCardWidth),
            height: TranquilTheme.cardOuterHeight(for: TranquilTheme.sceneCardHeight)
        )
    }
}

private struct SceneCardLabel: View {
    let scene: Scene
    let isLocked: Bool
    var timeSuggestion: String? = nil

    @Environment(\.isFocused) private var isFocused
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }
    private var isFavorite: Bool { settings.isFavoriteScene(scene.id) }

    private var captionText: String? {
        var parts: [String] = []
        if let suggestion = timeSuggestion, !suggestion.isEmpty { parts.append(suggestion) }
        if !scene.description.isEmpty { parts.append(scene.description) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .center, spacing: TranquilTheme.cardCaptionSpacing) {
            ZStack {
                Group {
                    if let assetName = scene.localImageAsset {
                        Image(assetName)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 64))
                                    .foregroundColor(.white.opacity(0.4))
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

                if isLocked {
                    Color.black.opacity(0.25)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 64))
                        .foregroundColor(theme.accentColor)
                }

                if isLocked {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                Text("Premium")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(theme.premiumBadgeColor.opacity(0.9))
                            .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    .padding(TranquilTheme.cardBadgeInset)
                }

                if isFavorite && !isLocked {
                    VStack {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.45)))
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(TranquilTheme.cardBadgeInset)
                }

                VStack {
                    Spacer()
                    Text(scene.name)
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

            if let caption = captionText {
                Text(caption)
                    .font(TranquilTheme.cardCaptionFont)
                    .foregroundColor(.white.opacity(isFocused ? 0.82 : 0.65))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: TranquilTheme.sceneCardWidth,
                           height: TranquilTheme.cardCaptionHeight,
                           alignment: .top)
            } else {
                Color.clear
                    .frame(width: TranquilTheme.sceneCardWidth, height: TranquilTheme.cardCaptionHeight)
            }
        }
    }
}

struct AudioCardView: View {
    let item: AudioOnlyItem
    let isLocked: Bool
    var prefersDefaultFocus: Bool = false
    var focusNamespace: Namespace.ID? = nil
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            AudioCardLabel(item: item, isLocked: isLocked)
        }
        .tranquilTVButton()
        .modifier(DefaultFocusModifier(isPreferred: prefersDefaultFocus, namespace: focusNamespace))
        .frame(
            width: TranquilTheme.cardOuterWidth(for: TranquilTheme.sceneCardWidth),
            height: TranquilTheme.cardOuterHeight(for: TranquilTheme.audioCardHeight)
        )
    }
}

private struct AudioCardLabel: View {
    let item: AudioOnlyItem
    let isLocked: Bool

    @Environment(\.isFocused) private var isFocused
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    private var categoryIcon: String {
        switch item.category {
        case "Forest": return "leaf.fill"
        case "Ocean": return "water.waves"
        case "Rain": return "cloud.rain.fill"
        case "Fireplace": return "flame.fill"
        case "Ambience": return "waveform"
        default: return "headphones"
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: TranquilTheme.cardCaptionSpacing) {
            ZStack {
                Group {
                    if let assetName = item.localImageAsset {
                        Image(assetName)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(theme.accentColor.opacity(0.25))
                            .overlay(
                                Image(systemName: categoryIcon)
                                    .font(.system(size: 64))
                                    .foregroundColor(theme.accentColor.opacity(0.8))
                            )
                    }
                }
                .frame(width: TranquilTheme.sceneCardWidth, height: TranquilTheme.audioCardHeight)
                .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.65), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )

                VStack {
                    HStack {
                        Text("Audio")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Spacer()
                        if isLocked {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                Text("Premium")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(theme.premiumBadgeColor.opacity(0.9))
                            .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
                .padding(TranquilTheme.cardBadgeInset)

                if isLocked {
                    Color.black.opacity(0.25)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 64))
                        .foregroundColor(theme.accentColor)
                }

                VStack {
                    Spacer()
                    Text(item.title)
                        .font(TranquilTheme.cardTitleFont)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .padding(.horizontal, TranquilTheme.cardTitleHorizontalPadding)
                        .padding(.bottom, TranquilTheme.cardTitleBottomPadding)
                }
            }
            .frame(width: TranquilTheme.sceneCardWidth, height: TranquilTheme.audioCardHeight)
            .clipShape(RoundedRectangle(cornerRadius: TranquilTheme.cardCornerRadius))
            .cardFocusChrome(
                isFocused: isFocused,
                cornerRadius: TranquilTheme.cardCornerRadius,
                accentColor: theme.accentColor
            )

            Text(item.category)
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

struct SectionHeaderView: View {
    let title: String
    let icon: String
    var iconSize: CGFloat = TranquilTheme.sectionIconSize

    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        HStack(spacing: TranquilTheme.sectionTitleToIconSpacing) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(theme.accentColor)
            Text(title)
                .font(TranquilTheme.sectionTitleFont)
                .foregroundColor(.white)
        }
    }
}
