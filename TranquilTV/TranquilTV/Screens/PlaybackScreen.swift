import SwiftUI
import AVKit
import UIKit

// Resets to false each app launch — never written to disk.
private enum SessionState {
    static var sleepTimerDefaultPromptShown = false
}

struct PlaybackScreen: View {
    @State private var activeContent: PlaybackContent

    @StateObject private var viewModel = PlaybackViewModel()
    @StateObject private var categoryPlayer = CategoryVideoPlayer()
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isSleepTransitionActive = false
    @State private var pendingTimerMinutes: Int? = nil   // chip tapped, awaiting default prompt

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
            // ── Background + playback controls ─────────────────────────────
            // Focus is disabled on all of this while the timer prompt is visible,
            // preventing the focus engine from reaching behind the overlay.
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

                if case .scene = activeContent {
                    Color.black.opacity(0.3).ignoresSafeArea()
                }

                if settings.audioOnlyMode, case .audioOnly = activeContent {
                    Color.black.opacity(0.88).ignoresSafeArea()
                }

                if isSleepTransitionActive {
                    Color.black.opacity(0.88)
                        .ignoresSafeArea()
                        .transition(.opacity.animation(.easeInOut(duration: 1.2)))
                }

                if viewModel.controlsVisible && pendingTimerMinutes == nil {
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
                        onTimerSelect: { mins in
                            viewModel.startSleepTimer(minutes: mins)
                            // Only show when: not suppressed, not shown this session,
                            // and no default timer is currently set (0 = Off).
                            if !settings.sleepTimerDefaultPromptSuppressed
                                && !SessionState.sleepTimerDefaultPromptShown
                                && settings.defaultSleepTimerMinutes == 0 {
                                pendingTimerMinutes = mins
                            }
                        },
                        onCancelTimer: { viewModel.cancelSleepTimer() },
                        onVolumeDown: { viewModel.setVolume(viewModel.volume - 0.05) },
                        onVolumeUp: { viewModel.setVolume(viewModel.volume + 0.05) },
                        onToggleMute: { viewModel.toggleMute() },
                        onInteraction: { viewModel.showControls() }
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                }

                PlaybackRemoteActivityBridge(
                    isCapturing: !viewModel.controlsVisible && pendingTimerMinutes == nil,
                    onActivity: { viewModel.showControls() }
                )
                .allowsHitTesting(false)
            }
            .opacity(pendingTimerMinutes != nil ? 0.35 : 1)

            // ── Sleep timer default prompt (on top, always focusable) ───────
            if let mins = pendingTimerMinutes {
                SleepTimerDefaultPrompt(
                    timerMinutes: mins,
                    onSetDefault: { doNotAsk in
                        settings.defaultSleepTimerMinutes = mins
                        if doNotAsk { settings.sleepTimerDefaultPromptSuppressed = true }
                        SessionState.sleepTimerDefaultPromptShown = true
                        pendingTimerMinutes = nil
                    },
                    onNo: { doNotAsk in
                        if doNotAsk { settings.sleepTimerDefaultPromptSuppressed = true }
                        SessionState.sleepTimerDefaultPromptShown = true
                        pendingTimerMinutes = nil
                    }
                )
                .focusSection()
                .zIndex(10)
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }

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
                // Dismiss back to home after the fade completes
                Task {
                    try? await Task.sleep(nanoseconds: 1_400_000_000)
                    await MainActor.run { dismiss() }
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
    @Published var player: AVQueuePlayer = {
        let player = AVQueuePlayer()
        // Prevent tvOS from surfacing system transport / scrubbing UI for ambient video.
        player.allowsExternalPlayback = false
        player.preventsDisplaySleepDuringVideoPlayback = true
        return player
    }()
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
            Task { @MainActor in
                guard let self else { return }
                self.currentIndex = (self.currentIndex + 1) % max(self.videoIds.count, 1)
                self.loadCurrentVideo()
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
        // Bare AVPlayerLayer — NO system transport controls. SwiftUI's `VideoPlayer`
        // renders tvOS native scrubbing UI on scene categories; audio categories have
        // no video surface, so match that experience here with a plain layer.
        PlayerLayerView(player: player.player)
            .allowsHitTesting(false)
            .focusable(false)
            .disabled(true)
    }
}

/// UIKit-backed view that displays an AVPlayer via AVPlayerLayer with no controls.
struct PlayerLayerView: UIViewRepresentable {
    let player: AVQueuePlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }
}

final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    override var canBecomeFocused: Bool { false }
}

// MARK: - Audio Only Background

struct AudioOnlyBackgroundView: View {
    let item: AudioOnlyItem

    var body: some View {
        // Pin everything to an explicit screen-sized frame and clip. Without a
        // bounded frame, `.scaledToFill()` overflows for images whose aspect
        // ratio doesn't match the screen (e.g. 4:3 "City Rain"), which grows
        // this view and shoves the sibling controls overlay off-screen.
        GeometryReader { geo in
            ZStack {
                Color(hex: 0x0A0A0A)
                if let name = item.localImageAsset {
                    // Same asset and fill as home-screen audio cards — no blur or dimming.
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
}

// MARK: - Controls Overlay

private enum PlaybackControlFocus: Hashable {
    case playPause
}

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
    @Namespace private var controlsFocusScope
    @FocusState private var focusedControl: PlaybackControlFocus?
    @Environment(\.resetFocus) private var resetFocus
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-screen vignette — heavy at top and bottom, transparent in middle
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0.55), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 220)
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.92)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 360)
            }
            .ignoresSafeArea()

            // Top bar — back button + title + timer badge
            VStack {
                HStack(alignment: .center, spacing: 20) {
                    // Back
                    FocusableCircleButton(icon: "chevron.left", size: 52) { onBack() }

                    // Title block
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.6), radius: 6, y: 2)
                        if !description.isEmpty {
                            Text(description)
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Sleep timer badge (top-right)
                    if let label = sleepTimerLabel {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.accentColor)
                            Text(label)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(theme.accentColor.opacity(0.5), lineWidth: 1.5)
                        )
                    }
                }
                .padding(.horizontal, 72)
                .padding(.top, 48)
                Spacer()
            }
            .focusSection()

            // Bottom control panel — default entry section for playback controls
            VStack(spacing: 0) {
                // ── Row 1: Volume  ·  Transport  ·  Actions ──────────────────
                HStack(alignment: .center) {

                    // LEFT — Volume cluster
                    HStack(spacing: 14) {
                        ControlButton(
                            icon: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                            size: 48,
                            tint: isMuted ? theme.accentColor : .white
                        ) { onToggleMute(); onInteraction() }

                        ControlButton(icon: "minus", size: 44) {
                            onVolumeDown(); onInteraction()
                        }

                        // Volume indicator bar
                        VolumeBar(percent: volumePercent, accentColor: theme.accentColor)
                            .frame(width: 90, height: 4)

                        ControlButton(icon: "plus", size: 44) {
                            onVolumeUp(); onInteraction()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // CENTRE — Prev / Play-Pause / Next
                    HStack(spacing: 28) {
                        ControlButton(icon: "backward.end.fill", size: 54) {
                            onPrevious(); onInteraction()
                        }
                        // Primary play button — larger, accent-tinted
                        PlayPauseButton(
                            isPlaying: isPlaying,
                            accentColor: theme.accentColor,
                            prefersDefaultFocus: true,
                            focusNamespace: controlsFocusScope,
                            focusBinding: $focusedControl
                        ) {
                            onPlayPause(); onInteraction()
                        }
                        ControlButton(icon: "forward.end.fill", size: 54) {
                            onNext(); onInteraction()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    // RIGHT — Timer chips + Favorite
                    HStack(spacing: 10) {
                        // "Off" chip — active when no timer is running
                        TimerChip(
                            label: "Off",
                            isSelected: selectedTimerMinutes == nil,
                            liveLabel: nil,
                            accentColor: theme.accentColor
                        ) { onCancelTimer(); onInteraction() }

                        ForEach([15, 30, 45, 60, 90], id: \.self) { mins in
                            TimerChip(
                                label: mins >= 60 ? "\(mins / 60)h" : "\(mins)m",
                                isSelected: selectedTimerMinutes == mins,
                                liveLabel: selectedTimerMinutes == mins ? sleepTimerLabel : nil,
                                accentColor: theme.accentColor
                            ) { onTimerSelect(mins); onInteraction() }
                        }
                        Divider()
                            .frame(height: 32)
                            .background(Color.white.opacity(0.2))
                            .padding(.horizontal, 4)
                        ControlButton(
                            icon: isFavorite ? "heart.fill" : "heart",
                            size: 50,
                            tint: isFavorite ? Color(hex: 0xFF6B9D) : .white
                        ) { onFavorite(); onInteraction() }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 72)
                .padding(.bottom, 52)
            }
            .focusScope(controlsFocusScope)
            .focusSection()
        }
        .onAppear { claimPlayPauseFocus() }
        .ignoresSafeArea()
    }

    private func claimPlayPauseFocus() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            resetFocus(in: controlsFocusScope)
            focusedControl = .playPause
        }
    }
}

// MARK: - Control Button (circle, reads isFocused via TranquilFocusButton)

private struct ControlButton: View {
    let icon: String
    var size: CGFloat = 48
    var tint: Color = .white
    let action: () -> Void

    var body: some View {
        TranquilFocusButton(action: action) { isFocused in
            ControlButtonLabel(icon: icon, size: size, tint: tint, isFocused: isFocused)
        }
    }
}

private struct ControlButtonLabel: View {
    let icon: String
    let size: CGFloat
    let tint: Color
    let isFocused: Bool
    @ObservedObject private var settings = SettingsService.shared
    private var accentColor: Color { settings.currentTheme.accentColor }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundColor(isFocused ? accentColor : tint)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isFocused
                          ? accentColor.opacity(0.18)
                          : Color.white.opacity(0.10))
            )
            .overlay(
                Circle()
                    .stroke(
                        isFocused ? accentColor.opacity(0.8) : Color.white.opacity(0.15),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .shadow(color: isFocused ? accentColor.opacity(0.45) : .clear, radius: 12)
            .scaleEffect(isFocused ? 1.10 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Play / Pause primary button

private struct PlayPauseButton: View {
    let isPlaying: Bool
    let accentColor: Color
    var prefersDefaultFocus: Bool = false
    var focusNamespace: Namespace.ID? = nil
    var focusBinding: FocusState<PlaybackControlFocus?>.Binding? = nil
    let action: () -> Void

    var body: some View {
        TranquilFocusButton(
            action: action,
            prefersDefaultFocus: prefersDefaultFocus,
            focusNamespace: focusNamespace
        ) { isFocused in
            PlayPauseLabel(isPlaying: isPlaying, accentColor: accentColor, isFocused: isFocused)
        }
        .modifier(PlayPauseFocusBindingModifier(binding: focusBinding))
    }
}

private struct PlayPauseFocusBindingModifier: ViewModifier {
    let binding: FocusState<PlaybackControlFocus?>.Binding?

    func body(content: Content) -> some View {
        if let binding {
            content.focused(binding, equals: .playPause)
        } else {
            content
        }
    }
}

private struct PlayPauseLabel: View {
    let isPlaying: Bool
    let accentColor: Color
    let isFocused: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isFocused ? accentColor : Color.white.opacity(0.15))
                .frame(width: 80, height: 80)
            Circle()
                .stroke(
                    isFocused ? accentColor : Color.white.opacity(0.3),
                    lineWidth: 2.5
                )
                .frame(width: 80, height: 80)
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(isFocused ? .black : .white)
                .offset(x: isPlaying ? 0 : 2)
        }
        .shadow(color: isFocused ? accentColor.opacity(0.6) : .black.opacity(0.4), radius: isFocused ? 20 : 10)
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Timer chip

private struct TimerChip: View {
    let label: String
    let isSelected: Bool
    let liveLabel: String?   // non-nil only when this chip is selected AND timer is ticking
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        TranquilFocusButton(action: action) { isFocused in
            TimerChipLabel(label: label, isSelected: isSelected,
                           liveLabel: liveLabel, accentColor: accentColor, isFocused: isFocused)
        }
    }
}

private struct TimerChipLabel: View {
    let label: String
    let isSelected: Bool
    let liveLabel: String?
    let accentColor: Color
    let isFocused: Bool

    private var displayText: String { liveLabel ?? label }
    private var isActive: Bool { isSelected || isFocused }

    var body: some View {
        Text(displayText)
            .font(.system(size: 17, weight: isActive ? .bold : .medium))
            .foregroundColor(isActive ? accentColor : .white.opacity(0.60))
            .monospacedDigit()
            .frame(minWidth: 48)
            .frame(height: 36)
            .padding(.horizontal, liveLabel != nil ? 10 : 0)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive
                          ? accentColor.opacity(0.18)
                          : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isActive ? accentColor.opacity(0.7) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Volume bar

private struct VolumeBar: View {
    let percent: Int
    let accentColor: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                Capsule()
                    .fill(accentColor)
                    .frame(width: geo.size.width * CGFloat(percent) / 100)
            }
        }
    }
}

// MARK: - Sleep Timer Default Prompt

private struct SleepTimerDefaultPrompt: View {
    let timerMinutes: Int
    let onSetDefault: (_ doNotAsk: Bool) -> Void
    let onNo: (_ doNotAsk: Bool) -> Void

    @ObservedObject private var settings = SettingsService.shared
    @State private var doNotAsk = false
    @State private var selectedMinutes: Int   // tracks chip selection without dismissing
    @FocusState private var focused: PromptFocus?
    @Namespace private var promptScope
    @Environment(\.resetFocus) private var resetFocus

    init(timerMinutes: Int,
         onSetDefault: @escaping (_ doNotAsk: Bool) -> Void,
         onNo: @escaping (_ doNotAsk: Bool) -> Void) {
        self.timerMinutes = timerMinutes
        self.onSetDefault = onSetDefault
        self.onNo = onNo
        _selectedMinutes = State(initialValue: timerMinutes)
    }

    private var theme: AppTheme { settings.currentTheme }
    private let options = [0, 15, 30, 45, 60, 90, 120]

    private func label(for mins: Int) -> String {
        if mins == 0 { return "Off" }
        if mins >= 60 { return "\(mins / 60)h\(mins % 60 > 0 ? "\(mins % 60)m" : "")" }
        return "\(mins)m"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 40) {
                // Header
                HStack(spacing: 18) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 44))
                        .foregroundColor(theme.accentColor)
                    Text("Set as Default Timer?")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Set \(label(for: selectedMinutes)) as your default sleep timer, or choose a different default below.")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 860)

                timerOptionsRow

                // No / Set buttons — full width, no cap
                HStack(spacing: 24) {
                    Button { onNo(doNotAsk) } label: {
                        NoButtonLabel(theme: theme, isFocused: focused == .no)
                    }
                    .tranquilTVButton()
                    .focused($focused, equals: .no)

                    Button {
                        settings.defaultSleepTimerMinutes = selectedMinutes
                        onSetDefault(doNotAsk)
                    } label: {
                        YesButtonLabel(minutes: selectedMinutes, label: label(for: selectedMinutes), theme: theme, isFocused: focused == .yes)
                    }
                    .tranquilTVButton()
                    .focused($focused, equals: .yes)
                    .prefersDefaultFocus(true, in: promptScope)
                }

                // Do not ask again toggle
                TranquilFocusButton(action: { doNotAsk.toggle() }) { isFocused in
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(doNotAsk ? theme.accentColor : Color.white.opacity(0.15))
                                .frame(width: 38, height: 38)
                            if doNotAsk {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isFocused ? theme.accentColor : Color.white.opacity(0.3), lineWidth: 2))

                        Text("Don't ask again")
                            .font(.system(size: 26))
                            .foregroundColor(.white.opacity(isFocused ? 0.9 : 0.55))
                    }
                    .animation(.easeInOut(duration: 0.15), value: doNotAsk)
                }
                .buttonStyle(.plain)
            }
            .padding(64)
            .background(
                RoundedRectangle(cornerRadius: 36)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.gradientColors.first?.opacity(0.96) ?? Color(hex: 0x0D0A25).opacity(0.96),
                                theme.gradientColors.last?.opacity(0.96) ?? Color(hex: 0x080615).opacity(0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(RoundedRectangle(cornerRadius: 36).stroke(theme.accentColor.opacity(0.3), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.5), radius: 40, y: 20)
            .frame(maxWidth: 1100)
            .focusScope(promptScope)
            .focusSection()
        }
        .onAppear { claimInitialFocus() }
        .onExitCommand { onNo(doNotAsk) }
    }

    private var timerOptionsRow: some View {
        HStack(spacing: 16) {
            ForEach(options, id: \.self) { mins in
                SleepTimerOptionChip(
                    label: label(for: mins),
                    isHighlighted: mins == selectedMinutes,
                    accentColor: theme.accentColor
                ) {
                    selectedMinutes = mins
                }
            }
        }
    }

    private func claimInitialFocus() {
        // Defer one run-loop turn so the prompt is in the tree before focus moves.
        DispatchQueue.main.async {
            resetFocus(in: promptScope)
            focused = .yes
        }
    }
}

private struct SleepTimerOptionChip: View {
    let label: String
    let isHighlighted: Bool
    let accentColor: Color
    let onSelect: () -> Void

    var body: some View {
        TranquilFocusButton(action: onSelect) { isFocused in
            Text(label)
                .font(.system(size: 26, weight: isHighlighted ? .bold : .medium))
                .foregroundColor(isHighlighted ? accentColor : (isFocused ? .white : .white.opacity(0.6)))
                .lineLimit(1)
                .fixedSize()
                .frame(minWidth: 100, minHeight: 62)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isHighlighted
                              ? accentColor.opacity(0.2)
                              : Color.white.opacity(isFocused ? 0.1 : 0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHighlighted ? accentColor : (isFocused ? accentColor.opacity(0.6) : Color.clear),
                                lineWidth: 2.5)
                )
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

private enum PromptFocus: Hashable { case yes, no }

private struct YesButtonLabel: View {
    let minutes: Int
    let label: String
    let theme: AppTheme
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
            Text("Set \(label) as Default")
                .font(.system(size: 32, weight: .bold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(RoundedRectangle(cornerRadius: 22).fill(isFocused ? theme.accentColor : theme.accentColor.opacity(0.65)))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(isFocused ? 0.35 : 0), lineWidth: 2.5))
        .scaleEffect(isFocused ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

private struct NoButtonLabel: View {
    let theme: AppTheme
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 32))
            Text("No")
                .font(.system(size: 32, weight: .bold))
        }
        .foregroundColor(.white.opacity(isFocused ? 1 : 0.65))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(isFocused ? 0.12 : 0.06)))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(isFocused ? theme.accentColor : Color.clear, lineWidth: 2.5))
        .scaleEffect(isFocused ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

#Preview {
    let scene = SceneService.shared.freeScenes[0]
    return PlaybackScreen(content: .scene(scene))
}
