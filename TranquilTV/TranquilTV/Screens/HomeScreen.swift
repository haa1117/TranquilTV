import SwiftUI

struct HomeScreen: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var settings = SettingsService.shared
    @State private var playbackContent: PlaybackContent? = nil
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var unlockContent: PremiumUnlockContent? = nil

    @Namespace private var focusNamespace

    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header is its own focus section — vertical nav cycles between
                // header and the content section cleanly.
                AppHeaderView(
                    isPremium: settings.isPremium,
                    focusNamespace: focusNamespace,
                    onSettingsTap: { showSettings = true },
                    onUpgradeTap: { showPaywall = true }
                )
                .focusSection()

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: TranquilTheme.rowSpacing) {
                        // Hero card — full-width, time-driven scheduled mood or featured fallback.
                        ScheduledMoodHeroCard(
                            onSelect: { handleSceneSelect($0) },
                            onLocked: { unlockContent = .scene($0) },
                            prefersDefaultFocus: true,
                            focusNamespace: focusNamespace
                        )

                        if viewModel.hasAnyFavorites {
                            favoritesRow()
                        }

                        audioOnlyRow()

                        categoryRow(
                            title: "Free Scenes",
                            icon: "leaf.fill",
                            scenes: viewModel.freeScenes
                        )

                        premiumScenesRow()

                        bundlesRow()
                    }
                    .padding(.bottom, 80)
                }
                .focusSection()
            }
        }
        .fullScreenCover(item: $playbackContent) { content in
            PlaybackScreen(content: content)
        }
        .fullScreenCover(isPresented: $showSettings) { SettingsScreen() }
        .fullScreenCover(isPresented: $showPaywall) { PaywallScreen() }
        .fullScreenCover(item: $unlockContent) { content in
            PremiumUnlockDialog(content: content) { action in
                switch action {
                case .cancel, .buyPremium, .buyCategory, .buyBundle, .restore:
                    unlockContent = nil
                }
            }
        }
        .onAppear {
            AnalyticsService.logScreenView("home_screen")
        }
    }

    // MARK: - Row builders

    @ViewBuilder
    private func categoryRow(title: String, icon: String, scenes: [Scene]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeaderView(title: title, icon: icon)
                .padding(.leading, TranquilTheme.standardPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: TranquilTheme.cardSpacing) {
                    ForEach(Array(scenes.enumerated()), id: \.element.id) { index, scene in
                        SceneCardView(
                            scene: scene,
                            isLocked: !viewModel.canAccess(scene: scene),
                            prefersDefaultFocus: false,
                            focusNamespace: focusNamespace
                        ) {
                            handleSceneSelect(scene)
                        }
                        .id(index)
                    }
                }
                .padding(.leading, TranquilTheme.focusEdgeInset)
                .padding(.trailing, TranquilTheme.focusEdgeInset)
                .padding(.vertical, 12)
            }
            .zIndex(1)
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
            .padding(.leading, TranquilTheme.standardPadding)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: TranquilTheme.cardSpacing) {
                        ForEach(Array(viewModel.premiumScenes.enumerated()), id: \.element.id) { index, scene in
                            SceneCardView(
                                scene: scene,
                                isLocked: !viewModel.canAccess(scene: scene),
                                prefersDefaultFocus: index == 0,
                                focusNamespace: focusNamespace
                            ) {
                                handleSceneSelect(scene)
                            }
                            .id(index)
                        }
                    }
                    .padding(.leading, TranquilTheme.focusEdgeInset)
                    .padding(.trailing, TranquilTheme.focusEdgeInset)
                    .padding(.vertical, 12)
                }
                .zIndex(1)
            }
        }
    }

    @ViewBuilder
    private func favoritesRow() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeaderView(title: "Favorites", icon: "heart.fill")
                .padding(.leading, TranquilTheme.standardPadding)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: TranquilTheme.cardSpacing) {
                        ForEach(Array(viewModel.favoriteScenes.enumerated()), id: \.element.id) { index, scene in
                            SceneCardView(
                                scene: scene,
                                isLocked: !viewModel.canAccess(scene: scene),
                                prefersDefaultFocus: index == 0,
                                focusNamespace: focusNamespace
                            ) {
                                handleSceneSelect(scene)
                            }
                            .id(index)
                        }
                        ForEach(Array(viewModel.favoriteAudioItems.enumerated()), id: \.element.id) { index, item in
                            AudioCardView(
                                item: item,
                                isLocked: !viewModel.canAccess(audio: item),
                                prefersDefaultFocus: viewModel.favoriteScenes.isEmpty && index == 0,
                                focusNamespace: focusNamespace
                            ) {
                                handleAudioSelect(item)
                            }
                            .id("a\(index)")
                        }
                    }
                    .padding(.leading, TranquilTheme.focusEdgeInset)
                    .padding(.trailing, TranquilTheme.focusEdgeInset)
                    .padding(.vertical, 12)
                }
                .zIndex(1)
            }
        }
    }

    @ViewBuilder
    private func audioOnlyRow() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeaderView(title: "Audio Only", icon: "headphones")
                .padding(.leading, TranquilTheme.standardPadding)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: TranquilTheme.cardSpacing) {
                        ForEach(Array(viewModel.audioOnlyItems.enumerated()), id: \.element.id) { index, item in
                            AudioCardView(
                                item: item,
                                isLocked: !viewModel.canAccess(audio: item),
                                prefersDefaultFocus: index == 0,
                                focusNamespace: focusNamespace
                            ) {
                                handleAudioSelect(item)
                            }
                            .id(index)
                        }
                    }
                    .padding(.leading, TranquilTheme.focusEdgeInset)
                    .padding(.trailing, TranquilTheme.focusEdgeInset)
                    .padding(.vertical, 12)
                }
                .zIndex(1)
            }
        }
    }

    @ViewBuilder
    private func bundlesRow() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.accentColor)
                Text("Bundles")
                    .font(TranquilTheme.sectionTitleFont)
                    .foregroundColor(.white)
            }
            .padding(.leading, TranquilTheme.standardPadding)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: TranquilTheme.cardSpacing) {
                        ForEach(Array(viewModel.paidPacks.enumerated()), id: \.element.id) { index, pack in
                            PackCardView(
                                pack: pack,
                                isPurchased: settings.isPackPurchased(pack),
                                prefersDefaultFocus: index == 0,
                                focusNamespace: focusNamespace
                            ) {
                                handlePackSelect(pack)
                            }
                            .id(index)
                        }
                    }
                    .padding(.leading, TranquilTheme.focusEdgeInset)
                    .padding(.trailing, TranquilTheme.focusEdgeInset)
                    .padding(.vertical, 12)
                }
                .zIndex(1)
            }
        }
    }

    // MARK: - Navigation

    private func handleSceneSelect(_ scene: Scene) {
        AnalyticsService.logSceneTapped(sceneId: scene.id, sceneName: scene.name,
                                         category: scene.category, isFree: scene.isFree, section: "home")
        if viewModel.canAccess(scene: scene) {
            playbackContent = .scene(scene)
        } else {
            unlockContent = .scene(scene)
        }
    }

    private func handleAudioSelect(_ item: AudioOnlyItem) {
        if viewModel.canAccess(audio: item) {
            playbackContent = .audioOnly(item)
        } else {
            unlockContent = .audio(item)
        }
    }

    private func handlePackSelect(_ pack: PackDefinition) {
        if settings.isPackPurchased(pack) || pack.isFree { return }
        unlockContent = .pack(pack)
    }
}

#Preview {
    HomeScreen()
}
