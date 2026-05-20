import SwiftUI
import AVKit

struct PlaybackScreen: View {
    let content: PlaybackContent

    @StateObject private var viewModel = PlaybackViewModel()
    @StateObject private var categoryPlayer = CategoryVideoPlayer()
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss

    private var theme: AppTheme { settings.currentTheme }
    private var displayTitle: String {
        switch content {
        case .scene(let s): return s.name
        case .audioOnly(let a): return a.title
        }
    }
    private var displayDescription: String {
        switch content {
        case .scene(let s): return s.description
        case .audioOnly: return ""
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Background: video or audio artwork
            switch content {
            case .scene:
                CategoryVideoPlayerView(player: categoryPlayer)
                    .ignoresSafeArea()
            case .audioOnly(let item):
                AudioOnlyBackgroundView(item: item)
                    .ignoresSafeArea()
            }

            // Dark scrim for readability
            Color.black.opacity(0.3).ignoresSafeArea()

            // Sleep transition overlay
            if viewModel.sleepTimerRemaining == 0 {
                Color.black.opacity(0.88).ignoresSafeArea()
            }

            // Controls overlay
            if viewModel.controlsVisible {
                ControlsOverlayView(
                    title: displayTitle,
                    description: displayDescription,
                    isPlaying: viewModel.isPlaying,
                    isFavorite: viewModel.isFavorite,
                    isAudioMode: viewModel.isAudioOnlyMode,
                    sleepTimerLabel: viewModel.sleepTimerLabel(),
                    selectedTimerMinutes: viewModel.selectedSleepTimerMinutes,
                    onBack: { dismiss() },
                    onPlayPause: { viewModel.togglePlayPause() },
                    onPrevious: { navigatePrevious() },
                    onNext: { navigateNext() },
                    onFavorite: { viewModel.toggleFavorite() },
                    onTimerSelect: { mins in viewModel.startSleepTimer(minutes: mins) },
                    onInteraction: { viewModel.showControls() }
                )
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            setupPlayback()
        }
        .onDisappear {
            viewModel.cleanup()
            categoryPlayer.stop()
        }
        .onTapGesture {
            viewModel.showControls()
        }
        // tvOS remote swipe/tap to show controls
        .onMoveCommand { _ in
            viewModel.showControls()
        }
    }

    // MARK: - Setup

    private func setupPlayback() {
        viewModel.loadContent(content)
        switch content {
        case .scene(let scene):
            let ids = VideoPlaylistService.shared.videoIds(forCategory: scene.category)
            categoryPlayer.start(videoIds: ids, category: scene.category)
        case .audioOnly:
            break
        }
    }

    // MARK: - Navigation

    private func navigatePrevious() {
        switch content {
        case .scene(let scene):
            let all = SceneService.shared.scenesInHomeOrder()
            if let idx = all.firstIndex(where: { $0.id == scene.id }) {
                let prevIdx = idx > 0 ? idx - 1 : all.count - 1
                let prev = all[prevIdx]
                if settings.canAccessScene(prev) {
                    categoryPlayer.stop()
                    let ids = VideoPlaylistService.shared.videoIds(forCategory: prev.category)
                    categoryPlayer.start(videoIds: ids, category: prev.category)
                }
            }
        case .audioOnly(let item):
            let all = AudioOnlyService.shared.allItems
            if let idx = all.firstIndex(where: { $0.id == item.id }) {
                let prev = all[idx > 0 ? idx - 1 : all.count - 1]
                viewModel.loadAudio(prev)
            }
        }
        viewModel.showControls()
    }

    private func navigateNext() {
        switch content {
        case .scene(let scene):
            let all = SceneService.shared.scenesInHomeOrder()
            if let idx = all.firstIndex(where: { $0.id == scene.id }) {
                let nextIdx = idx < all.count - 1 ? idx + 1 : 0
                let next = all[nextIdx]
                if settings.canAccessScene(next) {
                    categoryPlayer.stop()
                    let ids = VideoPlaylistService.shared.videoIds(forCategory: next.category)
                    categoryPlayer.start(videoIds: ids, category: next.category)
                }
            }
        case .audioOnly(let item):
            let all = AudioOnlyService.shared.allItems
            if let idx = all.firstIndex(where: { $0.id == item.id }) {
                let next = all[idx < all.count - 1 ? idx + 1 : 0]
                viewModel.loadAudio(next)
            }
        }
        viewModel.showControls()
    }
}

// MARK: - Category Video Player

@MainActor
class CategoryVideoPlayer: ObservableObject {
    @Published var player: AVQueuePlayer = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private var videoIds: [Int] = []
    private var category: String = ""
    private var currentIndex = 0

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
        Task {
            do {
                let urls = try await PexelsVideoService.shared.videoURLs(forId: id)
                if let url = urls.first {
                    await MainActor.run {
                        let item = AVPlayerItem(url: url)
                        self.player.removeAllItems()
                        self.player.insert(item, after: nil)
                        self.player.volume = 0.0
                        self.player.play()
                        // Preload next
                        self.prefetchNext()
                    }
                } else {
                    startFallback()
                }
            } catch {
                startFallback()
            }
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
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: player as! AVQueuePlayer, templateItem: item)
        player.volume = 0
        player.play()
    }

    func stop() {
        player.pause()
        player.removeAllItems()
        looper = nil
    }
}

struct CategoryVideoPlayerView: View {
    @ObservedObject var player: CategoryVideoPlayer

    var body: some View {
        VideoPlayer(player: player.player)
            .disabled(true) // tvOS remote should not control the player directly
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
    let isAudioMode: Bool
    let sleepTimerLabel: String?
    let selectedTimerMinutes: Int?
    let onBack: () -> Void
    let onPlayPause: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onFavorite: () -> Void
    let onTimerSelect: (Int) -> Void
    let onInteraction: () -> Void

    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ZStack {
            // Gradient scrim at top and bottom
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

            // Top-left: back + title
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
                    // Sleep timer display
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

            // Bottom: playback controls
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    // Left group: prev / play / next
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

                    // Right group: sleep timer + favorite
                    HStack(spacing: 16) {
                        ForEach([15, 30, 60, 90], id: \.self) { mins in
                            timerButton(minutes: mins)
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
        Button {
            onTimerSelect(minutes)
            onInteraction()
        } label: {
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
