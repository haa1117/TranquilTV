import SwiftUI

struct HomeScreen: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var settings = SettingsService.shared
    @State private var navigationPath = NavigationPath()
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var paywallProductId: String? = nil
    @State private var paywallProductTitle: String? = nil
    @State private var bundlePickerPack: PackDefinition? = nil
    @State private var lockedScene: Scene? = nil
    @State private var lockedAudio: AudioOnlyItem? = nil
    @State private var showLockedSceneAlert = false
    @State private var showLockedAudioAlert = false

    private var theme: AppTheme { settings.currentTheme }

    /// Unique focus keys per home row — scenes can appear in multiple rows (Featured + Free).
    private enum HomeFocusKey {
        static func featured(sceneId: String) -> String { "featured-\(sceneId)" }
        static func free(sceneId: String) -> String { "free-\(sceneId)" }
        static func premium(sceneId: String) -> String { "premium-\(sceneId)" }
        static func favoriteScene(sceneId: String) -> String { "favorite-scene-\(sceneId)" }
        static func favoriteAudio(itemId: String) -> String { "favorite-audio-\(itemId)" }
        static func audio(itemId: String) -> String { "audio-\(itemId)" }
        static func pack(packId: String) -> String { "pack-\(packId)" }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                LinearGradient(
                    colors: theme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                AmbientBackgroundView()

                VStack(spacing: 0) {
                    // Header
                    AppHeaderView(
                        isPremium: settings.isPremium,
                        onSettingsTap: { showSettings = true },
                        onUpgradeTap: { openPaywall(productId: nil, title: nil) }
                    )

                    // Scrollable content rows
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: TranquilTheme.sectionSpacing) {
                            // Featured
                            categoryRow(
                                title: "Featured",
                                icon: "sparkles",
                                scenes: viewModel.featuredScenes
                            )

                            // Favorites (only when user has favorites)
                            if viewModel.hasAnyFavorites {
                                favoritesRow()
                            }

                            // Audio Only
                            audioOnlyRow()

                            // Free Scenes
                            categoryRow(
                                title: "Free Scenes",
                                icon: "leaf.fill",
                                scenes: viewModel.freeScenes,
                                sectionKey: "free"
                            )

                            // Premium Scenes
                            premiumScenesRow()
                        }
                        .padding(.horizontal, TranquilTheme.standardPadding)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationDestination(for: PlaybackContent.self) { content in
                PlaybackScreen(content: content)
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsScreen()
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallScreen(productId: paywallProductId, productTitle: paywallProductTitle)
            }
            .fullScreenCover(item: $bundlePickerPack) { pack in
                BundlePickerScreen(
                    pack: pack,
                    onSelectScene: { scene in
                        bundlePickerPack = nil
                        settings.lastPlayedContentType = .scene
                        settings.lastPlayedSceneId = scene.id
                        navigationPath.append(PlaybackContent.scene(scene))
                    },
                    onDismiss: { bundlePickerPack = nil }
                )
            }
            .alert("Premium Scene", isPresented: $showLockedSceneAlert, presenting: lockedScene) { scene in
                Button("Subscribe Monthly") {
                    showPaywall = true
                }
                if let pid = settings.oneTimeProductForSceneCategory(scene.category) {
                    Button("Buy Once") {
                        // StoreKit purchase handled in PaywallScreen for now
                        showPaywall = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { scene in
                Text("Unlock \"\(scene.name)\" with a Premium subscription or a one-time purchase.")
            }
            .alert("Premium Audio", isPresented: $showLockedAudioAlert, presenting: lockedAudio) { item in
                Button("Subscribe Monthly") {
                    showPaywall = true
                }
                Button("Cancel", role: .cancel) {}
            } message: { item in
                Text("Unlock \"\(item.title)\" with a Premium subscription.")
            }
        }
        .onAppear {
            AnalyticsService.logScreenView("home_screen")
        }
    }

    // MARK: - Row builders

    /// Full-width horizontal row — matches Android `clipBehavior: Clip.none` so cards
    /// scroll off the screen edge instead of being clipped by section padding.
    @ViewBuilder
    private func horizontalCardScroll<Content: View>(
        height: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HorizontalCardScrollRow(height: height, content: content)
    }

    @ViewBuilder
    private func categoryRow(title: String, icon: String, scenes: [Scene]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeaderView(title: title, icon: icon)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TranquilTheme.cardSpacing) {
                    ForEach(scenes) { scene in
                        SceneCardView(
                            scene: scene,
                            isLocked: !viewModel.canAccess(scene: scene)
                        ) {
                            handleSceneSelect(scene)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private func premiumScenesRow() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: settings.isPremium ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.accentColor)
                Text("Premium Scenes")
                    .font(TranquilTheme.sectionTitleFont)
                    .foregroundColor(.white)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: TranquilTheme.cardSpacing) {
                    ForEach(viewModel.premiumScenes) { scene in
                        SceneCardView(
                            scene: scene,
                            isLocked: !viewModel.canAccess(scene: scene)
                        ) {
                            handleSceneSelect(scene)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private func favoritesRow() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeaderView(title: "Favorites", icon: "heart.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: TranquilTheme.cardSpacing) {
                    ForEach(viewModel.favoriteScenes) { scene in
                        SceneCardView(
                            scene: scene,
                            isLocked: !viewModel.canAccess(scene: scene)
                        ) {
                            handleSceneSelect(scene)
                        }
                    }
                    ForEach(viewModel.favoriteAudioItems) { item in
                        AudioCardView(
                            item: item,
                            isLocked: !viewModel.canAccess(audio: item)
                        ) {
                            handleAudioSelect(item)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private func audioOnlyRow() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeaderView(title: "Audio Only", icon: "headphones")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: TranquilTheme.cardSpacing) {
                    ForEach(viewModel.audioOnlyItems) { item in
                        AudioCardView(
                            item: item,
                            isLocked: !viewModel.canAccess(audio: item),
                            focusNamespace: homeFocusScope
                        ) {
                            handleAudioSelect(item)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 20)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .focusSection()
        }
    }

    // MARK: - Navigation

    private func openPaywall(productId: String?, title: String?) {
        paywallProductId = productId
        paywallProductTitle = title
        showPaywall = true
    }

    private func handleSceneSelect(_ scene: Scene) {
        AnalyticsService.logSceneTapped(sceneId: scene.id, sceneName: scene.name,
                                         category: scene.category, isFree: scene.isFree, section: "home")
        if viewModel.canAccess(scene: scene) {
            navigationPath.append(PlaybackContent.scene(scene))
        } else {
            lockedScene = scene
            showLockedSceneAlert = true
        }
    }

    private func handleAudioSelect(_ item: AudioOnlyItem) {
        if viewModel.canAccess(audio: item) {
            navigationPath.append(PlaybackContent.audioOnly(item))
        } else {
            lockedAudio = item
            showLockedAudioAlert = true
        }
    }
}

// Make PlaybackContent NavigationPath-compatible
extension PlaybackContent: Hashable {
    static func == (lhs: PlaybackContent, rhs: PlaybackContent) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

#Preview {
    HomeScreen()
}
