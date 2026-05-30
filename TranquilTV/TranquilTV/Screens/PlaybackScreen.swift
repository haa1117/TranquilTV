import SwiftUI
import AVKit

struct PlaybackScreen: View {
    @State private var activeContent: PlaybackContent

    @StateObject private var viewModel = PlaybackViewModel()
    @StateObject private var categoryPlayer = CategoryVideoPlayer()
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isSleepTransitionActive = false

    init(content: PlaybackContent) {
        _activeContent = State(initialValue: content)
    }

    private var theme: AppTheme { settings.currentTheme }
    private var displayTitle: String {
        switch activeContent {
        case .scene(let s): return s.name
        case .audioOnly(let a): return a.title
        }
    }
    private var displayDescription: String {
        switch activeContent {
        case .scene(let s): return s.description
        case .audioOnly: return ""
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch activeContent {
            case .scene:
                CategoryVideoPlayerView(player: categoryPlayer)
                    .ignoresSafeArea()
            case .audioOnly(let item):
                AudioOnlyBackgroundView(item: item)
                    .ignoresSafeArea()
            }

            Color.black.opacity(0.3).ignoresSafeArea()

            // Audio-only dim mode (Android `audioOnlyMode` setting)
            if settings.audioOnlyMode, case .audioOnly = activeContent {
                Color.black.opacity(0.88).ignoresSafeArea()
            }

            if isSleepTransitionActive {
                Color.black.opacity(0.88)
                    .ignoresSafeArea()
                    .transition(.opacity.animation(.easeInOut(duration: 1.2)))
            }

            if viewModel.controlsVisible {
                ControlsOverlayView(
                    title: displayTitle,
                    description: displayDescription,
                    isPlaying: viewModel.isPlaying,
                    isFavorite: viewModel.isFavorite,
                    isMuted: viewModel.isMuted,
                    volumePercent: Int(viewModel.volume * 100),
                    isAudioMode: viewModel.isAudioOnlyMode,
                    sleepTimerLabel: viewModel.sleepTimerLabel(),
                    selectedTimerMinutes: viewModel.selectedSleepTimerMinutes,
                    onBack: { dismiss() },
                    onPlayPause: { viewModel.togglePlayPause() },
                    onPrevious: { navigatePrevious() },
                    onNext: { navigateNext() },
                    onFavorite: { viewModel.toggleFavorite() },
                    onTimerSelect: { mins in viewModel.startSleepTimer(minutes: mins) },
                    onCancelTimer: { viewModel.cancelSleepTimer() },
                    onVolumeDown: { viewModel.setVolume(viewModel.volume - 0.05) },
                    onVolumeUp: { viewModel.setVolume(viewModel.volume + 0.05) },
                    onToggleMute: { viewModel.toggleMute() },
                    onInteraction: { viewModel.showControls() }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }

            // Capture Siri Remote input when controls are hidden (VideoPlayer steals focus otherwise).
            PlaybackRemoteActivityBridge(
                isCapturing: !viewModel.controlsVisible,
                onActivity: { viewModel.showControls() }
            )
            .allowsHitTesting(false)

            if categoryPlayer.isDownloading {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.7)
                                .tint(.white)
                            Text("Downloading…")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(.top, 40)
                        .padding(.trailing, 36)
                    }
                    Spacer()
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }

            if let error = viewModel.errorMessage {
                VStack {
                    Text(error)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.75))
                        .clipShape(Capsule())
                        .padding(.top, 48)
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            setupPlayback(for: activeContent)
            viewModel.onSleepTimerExpired = {
                withAnimation(.easeInOut(duration: 1.2)) {
                    isSleepTransitionActive = true
                }
            }
        }
        .onDisappear {
            viewModel.cleanup()
            categoryPlayer.stop()
        }
        .onTapGesture {
            viewModel.showControls()
        }
        .onMoveCommand { _ in
            viewModel.showControls()
        }
    }

    private func setupPlayback(for content: PlaybackContent) {
        viewModel.sceneVideoPlayer = categoryPlayer.player
        viewModel.loadContent(content)
        switch content {
        case .scene(let scene):
            categoryPlayer.startFallbackImmediately()
            let ids = VideoPlaylistService.shared.videoIds(forCategory: scene.category)
            categoryPlayer.start(videoIds: ids, category: scene.category)
            viewModel.applyDefaultSleepTimerIfNeeded()
        case .audioOnly:
            viewModel.applyDefaultSleepTimerIfNeeded()
            break
        }
    }

    private func navigateToScene(_ scene: Scene) {
        guard settings.canAccessScene(scene) else { return }
        settings.lastPlayedContentType = .scene
        settings.lastPlayedSceneId = scene.id
        activeContent = .scene(scene)
        categoryPlayer.stop()
        viewModel.sceneVideoPlayer = categoryPlayer.player
        viewModel.loadScene(scene)
        categoryPlayer.startFallbackImmediately()
        let ids = VideoPlaylistService.shared.videoIds(forCategory: scene.category)
        categoryPlayer.start(videoIds: ids, category: scene.category)
    }

    private func navigateToAudio(_ item: AudioOnlyItem) {
        settings.lastPlayedContentType = .audioOnly
        settings.lastPlayedAudioOnlyId = item.id
        activeContent = .audioOnly(item)
        categoryPlayer.stop()
        viewModel.loadAudio(item)
    }

    private func navigatePrevious() {
        switch activeContent {
        case .scene(let scene):
            let all = SceneService.shared.scenesInHomeOrder()
            if let idx = all.firstIndex(where: { $0.id == scene.id }) {
                let prev = all[idx > 0 ? idx - 1 : all.count - 1]
                navigateToScene(prev)
            }
        case .audioOnly(let item):
            let all = AudioOnlyService.shared.allItems
            if let idx = all.firstIndex(where: { $0.id == item.id }) {
                let prev = all[idx > 0 ? idx - 1 : all.count - 1]
                if settings.canAccessAudio(prev) {
                    navigateToAudio(prev)
                }
            }
        }
        viewModel.showControls()
    }

    private func navigateNext() {
        switch activeContent {
        case .scene(let scene):
            let all = SceneService.shared.scenesInHomeOrder()
            if let idx = all.firstIndex(where: { $0.id == scene.id }) {
                let next = all[idx < all.count - 1 ? idx + 1 : 0]
                navigateToScene(next)
            }
        case .audioOnly(let item):
            let all = AudioOnlyService.shared.allItems
            if let idx = all.firstIndex(where: { $0.id == item.id }) {
                let next = all[idx < all.count - 1 ? idx + 1 : 0]
                if settings.canAccessAudio(next) {
                    navigateToAudio(next)
                }
            }
        }
        viewModel.showControls()
    }
}

// MARK: - Category Video Player

@MainActor
class CategoryVideoPlayer: ObservableObject {
    @Published var player: AVQueuePlayer = AVQueuePlayer()
    @Published var isDownloading = false
    private var looper: AVPlayerLooper?
    private var videoIds: [Int] = []
    private var category: String = ""
    private var currentIndex = 0
    private var endObserver: NSObjectProtocol?

    func startFallbackImmediately() {
        guard looper == nil, player.items().isEmpty else { return }
        startFallback()
    }

    func start(videoIds: [Int], category: String) {
        guard !videoIds.isEmpty else {
            startFallback()
            return
        }
        self.videoIds = videoIds.shuffled()
        self.category = category
        currentIndex = 0
        loadCurrentVideo()
    }

    private func loadCurrentVideo() {
        guard currentIndex < videoIds.count else { return }
        let id = videoIds[currentIndex]
        isDownloading = true
        Task {
            do {
                let urls = try await PexelsVideoService.shared.videoURLs(forId: id)
                if let url = urls.first {
                    await MainActor.run {
                        self.isDownloading = false
                        self.looper = nil
                        let item = AVPlayerItem(url: url)
                        self.player.removeAllItems()
                        self.player.insert(item, after: nil)
                        self.player.volume = 0.0
                        self.player.play()
                        self.installEndObserver(for: item)
                        self.prefetchNext()
                    }
                } else {
                    await MainActor.run { self.isDownloading = false }
                    startFallback()
                }
            } catch {
                await MainActor.run { self.isDownloading = false }
                startFallback()
            }
        }
    }

    private func installEndObserver(for item: AVPlayerItem) {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.currentIndex = (self.currentIndex + 1) % max(self.videoIds.count, 1)
            self.loadCurrentVideo()
        }
    }

    private func prefetchNext() {
        guard videoIds.count > 1 else { return }
        let nextIdx = (currentIndex + 1) % videoIds.count
        let nextId = videoIds[nextIdx]
        Task {
            if let urls = try? await PexelsVideoService.shared.videoURLs(forId: nextId),
               let url = urls.first {
                await MainActor.run {
                    let item = AVPlayerItem(url: url)
                    self.player.insert(item, after: nil)
                }
            }
        }
    }

    func startFallback() {
        guard let url = Bundle.main.url(forResource: "fallback_pexels_3571264", withExtension: "mp4") else { return }
        looper = nil
        player.removeAllItems()
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: player, templateItem: item)
        player.volume = 0
        player.play()
    }

    func stop() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        player.pause()
        player.removeAllItems()
        looper = nil
    }
}

struct CategoryVideoPlayerView: View {
    @ObservedObject var player: CategoryVideoPlayer

    var body: some View {
        VideoPlayer(player: player.player)
            .disabled(true)
            .focusable(false)
    }
}

// MARK: - Audio Only Background

struct AudioOnlyBackgroundView: View {
    let item: AudioOnlyItem

    var body: some View {
        ZStack {
            Color(hex: 0x0A0A0A)
            if let name = item.localImageAsset {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 20)
                    .opacity(0.4)
            }
        }
    }
}

// MARK: - Controls Overlay

struct ControlsOverlayView: View {
    let title: String
    let description: String
    let isPlaying: Bool
    let isFavorite: Bool
    let isMuted: Bool
    let volumePercent: Int
    let isAudioMode: Bool
    let sleepTimerLabel: String?
    let selectedTimerMinutes: Int?
    let onBack: () -> Void
    let onPlayPause: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onFavorite: () -> Void
    let onTimerSelect: (Int) -> Void
    let onCancelTimer: () -> Void
    let onVolumeDown: () -> Void
    let onVolumeUp: () -> Void
    let onToggleMute: () -> Void
    let onInteraction: () -> Void

    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ZStack {
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.7), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 200)
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 250)
            }
            .ignoresSafeArea()

            VStack {
                HStack(alignment: .top) {
                    HStack(spacing: 16) {
                        FocusableCircleButton(icon: "chevron.left", size: 56) {
                            onBack()
                        }
                        if !title.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.white)
                                    .shadow(radius: 4)
                                if !description.isEmpty {
                                    Text(description)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    Spacer()
                    if let label = sleepTimerLabel {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .foregroundColor(theme.accentColor)
                            Text(label)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, TranquilTheme.standardPadding)
                .padding(.top, 40)
                Spacer()
            }

            VStack {
                Spacer()
                HStack(alignment: .center) {
                    HStack(spacing: 20) {
                        FocusableCircleButton(icon: "chevron.left", size: 56) {
                            onPrevious()
                            onInteraction()
                        }
                        FocusableCircleButton(
                            icon: isPlaying ? "pause.fill" : "play.fill",
                            size: 72,
                            isPrimary: true
                        ) {
                            onPlayPause()
                            onInteraction()
                        }
                        FocusableCircleButton(icon: "chevron.right", size: 56) {
                            onNext()
                            onInteraction()
                        }
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        FocusableCircleButton(icon: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill", size: 48) {
                            onToggleMute()
                            onInteraction()
                        }
                        FocusableCircleButton(icon: "minus", size: 44) {
                            onVolumeDown()
                            onInteraction()
                        }
                        Text("\(volumePercent)%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 44)
                        FocusableCircleButton(icon: "plus", size: 44) {
                            onVolumeUp()
                            onInteraction()
                        }
                    }

                    Spacer()

                    HStack(spacing: 16) {
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { mins in
                            timerButton(minutes: mins)
                        }
                        if sleepTimerLabel != nil {
                            FocusableCircleButton(icon: "xmark", size: 44) {
                                onCancelTimer()
                                onInteraction()
                            }
                        }
                        FocusableCircleButton(
                            icon: isFavorite ? "heart.fill" : "heart",
                            size: 52
                        ) {
                            onFavorite()
                            onInteraction()
                        }
                    }
                }
                .padding(.horizontal, TranquilTheme.standardPadding)
                .padding(.bottom, 50)
            }
        }
    }

    @ViewBuilder
    private func timerButton(minutes: Int) -> some View {
        let isSelected = selectedTimerMinutes == minutes
        TranquilFocusButton(action: {
            onTimerSelect(minutes)
            onInteraction()
        }) {
            Text("\(minutes)m")
                .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? theme.accentColor : .white.opacity(0.7))
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(isSelected ? theme.accentColor.opacity(0.2) : Color.white.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .tvFocusStyle()
    }
}

#Preview {
    let scene = SceneService.shared.freeScenes[0]
    return PlaybackScreen(content: .scene(scene))
}
