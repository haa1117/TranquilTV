import SwiftUI

struct SceneCardView: View {
    let scene: Scene
    let isLocked: Bool
    var isFocused: Bool = false
    let onSelect: () -> Void

    @Environment(\.isFocused) private var envFocused
    @ObservedObject private var settings = SettingsService.shared

    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottomLeading) {
                // Thumbnail image
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
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.4))
                            )
                    }
                }
                .frame(width: TranquilTheme.cardWidth, height: TranquilTheme.cardHeight)
                .clipped()

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Title & lock indicator
                VStack(alignment: .leading, spacing: 4) {
                    if isLocked {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(theme.accentColor)
                            Text("Premium")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(theme.accentColor)
                        }
                    }
                    Text(scene.name)
                        .font(TranquilTheme.cardTitleFont)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(12)
            }
            .frame(width: TranquilTheme.cardWidth, height: TranquilTheme.cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: TranquilTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: TranquilTheme.cardCornerRadius)
                    .stroke(envFocused ? theme.accentColor : Color.clear, lineWidth: TranquilTheme.focusBorderWidth)
                    .shadow(color: envFocused ? theme.accentColor.opacity(0.6) : .clear, radius: 20)
            )
            .scaleEffect(envFocused ? TranquilTheme.cardScaleFocused : 1.0)
            .shadow(color: .black.opacity(envFocused ? 0.5 : 0.3), radius: envFocused ? 20 : 8, y: envFocused ? 12 : 4)
            .animation(.easeInOut(duration: 0.2), value: envFocused)
        }
        .buttonStyle(.plain)
        .frame(width: TranquilTheme.cardWidth, height: TranquilTheme.cardHeight)
    }
}

struct AudioCardView: View {
    let item: AudioOnlyItem
    let isLocked: Bool
    let onSelect: () -> Void

    @Environment(\.isFocused) private var envFocused
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
        Button(action: onSelect) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.accentColor.opacity(0.2))
                        .frame(width: 120, height: 120)
                    if let assetName = item.localImageAsset {
                        Image(assetName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 48))
                            .foregroundColor(theme.accentColor)
                    }
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .offset(x: 40, y: -40)
                    }
                }

                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 130)

                Text(item.category)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(envFocused ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(envFocused ? theme.accentColor : Color.clear, lineWidth: TranquilTheme.focusBorderWidth)
            )
            .scaleEffect(envFocused ? TranquilTheme.cardScaleFocused : 1.0)
            .shadow(color: envFocused ? theme.accentColor.opacity(0.4) : .clear, radius: 16)
            .animation(.easeInOut(duration: 0.2), value: envFocused)
        }
        .buttonStyle(.plain)
    }
}

struct SectionHeaderView: View {
    let title: String
    let icon: String

    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(theme.accentColor)
            Text(title)
                .font(TranquilTheme.sectionTitleFont)
                .foregroundColor(.white)
        }
    }
}
