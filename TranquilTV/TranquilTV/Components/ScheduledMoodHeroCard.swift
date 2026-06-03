import SwiftUI

struct ScheduledMoodHeroCard: View {
    let onSelect: (Scene) -> Void
    let onLocked: (Scene) -> Void
    var prefersDefaultFocus: Bool = false
    var focusNamespace: Namespace.ID? = nil

    @ObservedObject private var settings = SettingsService.shared
    @State private var now = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private var theme: AppTheme { settings.currentTheme }

    // MARK: - Computed

    private var activeBlock: ScheduledMoodBlockData? {
        guard settings.scheduledMoodsEnabled else { return nil }
        let hour   = Calendar.current.component(.hour,   from: now)
        let minute = Calendar.current.component(.minute, from: now)
        return settings.scheduledMoodBlocks.first { $0.contains(hour: hour, minute: minute) }
    }

    private var heroScene: Scene? {
        if let block = activeBlock {
            return SceneService.shared.allScenes.first { $0.category == block.moodCategory.sceneCategory }
        }
        return SceneService.shared.featuredScenes.first
    }

    private var isLocked: Bool {
        guard let scene = heroScene else { return false }
        return !settings.canAccessScene(scene)
    }

    // MARK: - Body

    var body: some View {
        if let scene = heroScene {
            GeometryReader { geo in
                TranquilFocusButton(
                    action: { isLocked ? onLocked(scene) : onSelect(scene) },
                    prefersDefaultFocus: prefersDefaultFocus,
                    focusNamespace: focusNamespace
                ) { isFocused in
                    HeroCardContent(
                        scene: scene,
                        isLocked: isLocked,
                        activeBlock: activeBlock,
                        theme: theme,
                        isFocused: isFocused,
                        width: geo.size.width
                    )
                }
            }
            .frame(height: 420)
            // Extra vertical padding so the focus scale (1.02) and border
            // never clip against the LazyVStack or ScrollView edges.
            .padding(.top, 20)
            .padding(.bottom, 8)
            .padding(.horizontal, TranquilTheme.standardPadding)
            .onReceive(timer) { now = $0 }
        }
    }
}

// MARK: - Card content

private struct HeroCardContent: View {
    let scene: Scene
    let isLocked: Bool
    let activeBlock: ScheduledMoodBlockData?
    let theme: AppTheme
    let isFocused: Bool
    let width: CGFloat

    private let cardHeight: CGFloat = 420
    @ObservedObject private var settings = SettingsService.shared
    private var isFavorite: Bool { settings.isFavoriteScene(scene.id) }

    var body: some View {
        ZStack {
            // Background artwork
            Group {
                if let assetName = scene.localImageAsset {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.25))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 96))
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
            }
            .frame(width: width, height: cardHeight)
            .clipped()

            // Bottom scrim
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.88), location: 0),
                    .init(color: .black.opacity(0.35), location: 0.45),
                    .init(color: .clear,               location: 1),
                ],
                startPoint: .bottom,
                endPoint: .top
            )

            // Lock dim
            if isLocked {
                Color.black.opacity(0.2)
            }

            // Overlay content
            VStack(alignment: .leading, spacing: 0) {
                // Top badges row
                HStack(alignment: .top) {
                    moodPill
                    Spacer()
                    topRightBadges
                }
                .padding(.top, 28)
                .padding(.horizontal, 32)

                Spacer()

                // Bottom text
                VStack(alignment: .leading, spacing: 10) {
                    Text(scene.name)
                        .font(.system(size: 52, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(scene.description)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        Image(systemName: isLocked ? "lock.fill" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text(isLocked ? "Unlock to Play" : "Press to Play")
                            .font(.system(size: 22, weight: .semibold))
                    }
                    .foregroundColor(isFocused ? theme.accentColor : .white.opacity(0.55))
                    .padding(.top, 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 36)
            }
            .frame(width: width, height: cardHeight, alignment: .leading)
        }
        .frame(width: width, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        // Focus chrome — border drawn outside the clip shape via padding trick
        .padding(isFocused ? 0 : 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    isFocused ? theme.accentColor : Color.white.opacity(0.10),
                    lineWidth: isFocused ? 4 : 1
                )
                .padding(isFocused ? 0 : 4)
        )
        .shadow(color: isFocused ? theme.accentColor.opacity(0.5) : Color.black.opacity(0.3),
                radius: isFocused ? 24 : 12)
        .animation(.easeInOut(duration: 0.18), value: isFocused)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var moodPill: some View {
        if let block = activeBlock {
            HStack(spacing: 8) {
                Image(systemName: block.moodCategory.icon)
                    .font(.system(size: 20, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.moodCategory.rawValue)
                        .font(.system(size: 22, weight: .bold))
                    Text(block.timeRangeLabel)
                        .font(.system(size: 17, weight: .regular))
                        .opacity(0.8)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                Text("Featured")
                    .font(.system(size: 22, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var topRightBadges: some View {
        HStack(spacing: 10) {
            if isFavorite && !isLocked {
                Image(systemName: "star.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.yellow)
                    .padding(10)
                    .background(Circle().fill(Color.black.opacity(0.45)))
            }
            if isLocked {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Premium")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(theme.premiumBadgeColor.opacity(0.9))
                .clipShape(Capsule())
            }
        }
    }
}
