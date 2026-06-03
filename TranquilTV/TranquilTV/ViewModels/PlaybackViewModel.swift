import Foundation
import AVFoundation
import Combine

enum PlaybackContent {
    case scene(Scene)
    case audioOnly(AudioOnlyItem)
}

@MainActor
class PlaybackViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var controlsVisible = true
    @Published var isFavorite = false
    @Published var sleepTimerRemaining: TimeInterval? = nil
    @Published var selectedSleepTimerMinutes: Int? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isMuted = false
    @Published var volume: Double = 0.8

    /// Category video player (muted); set from PlaybackScreen for scene mode.
    weak var sceneVideoPlayer: AVQueuePlayer?

    var audioPlayer: AVPlayer?
    private var audioLoopObserver: NSObjectProtocol?

    private(set) var currentContent: PlaybackContent?
    private var controlsHideTask: Task<Void, Never>?
    private var sleepTimerTask: Task<Void, Never>?
    private var sleepTimerTotal: TimeInterval = 0
    private var sleepTimerStarted: Date?
    private var playbackStartMs: Int = 0
    let settings = SettingsService.shared
    var onSleepTimerExpired: (() -> Void)?

    init() {
        volume = settings.defaultVolume
    }

    var currentScene: Scene? {
        if case .scene(let s) = currentContent { return s }
        return nil
    }
    var currentAudioOnly: AudioOnlyItem? {
        if case .audioOnly(let a) = currentContent { return a }
        return nil
    }
    var isAudioOnlyMode: Bool { currentAudioOnly != nil }

    func loadContent(_ content: PlaybackContent) {
        currentContent = content
        volume = settings.defaultVolume
        isMuted = false
        switch content {
        case .scene(let scene):
            loadScene(scene)
        case .audioOnly(let item):
            isFavorite = settings.isFavoriteAudio(item.id)
            loadAudio(item)
        }
        playbackStartMs = Int(Date().timeIntervalSince1970 * 1000)
        showControls()
        AnalyticsService.logPlaybackStarted(
            contentType: isAudioOnlyMode ? "audio_only" : "scene",
            contentId: content.id,
            contentName: content.name,
            category: content.category,
            isFree: content.isFree
        )
    }

    func loadScene(_ scene: Scene) {
        currentContent = .scene(scene)
        isFavorite = settings.isFavoriteScene(scene.id)
        stopAudioLoopObserver()
        audioPlayer?.pause()
        audioPlayer = nil

        if let url = URL(string: scene.audioUrl) {
            let player = AVPlayer(url: url)
            applyVolume(to: player)
            audioPlayer = player
            installAudioLoopObserver(for: player)
            player.play()
            isPlaying = true
        } else {
            errorMessage = "Unable to load scene audio"
            isPlaying = sceneVideoPlayer?.rate != 0
        }
    }

    func loadAudio(_ item: AudioOnlyItem) {
        currentContent = .audioOnly(item)
        isFavorite = settings.isFavoriteAudio(item.id)
        stopAudioLoopObserver()
        audioPlayer?.pause()
        audioPlayer = nil

        if let localName = item.localAudioAsset,
           let url = Bundle.main.url(forResource: (localName as NSString).deletingPathExtension,
                                     withExtension: (localName as NSString).pathExtension) {
            let player = AVPlayer(url: url)
            audioPlayer = player
        } else if let url = URL(string: item.audioSource) {
            audioPlayer = AVPlayer(url: url)
        }
        audioPlayer?.volume = Float(settings.defaultVolume)
        volume = settings.defaultVolume
        if let player = audioPlayer {
            applyVolume(to: player)
            installAudioLoopObserver(for: player)
            player.play()
        }
        isPlaying = true
    }

    func setVolume(_ value: Double) {
        volume = min(1, max(0, value))
        settings.defaultVolume = volume
        if let player = audioPlayer { applyVolume(to: player) }
        showControls()
    }

    func toggleMute() {
        isMuted.toggle()
        if let player = audioPlayer { applyVolume(to: player) }
        showControls()
    }

    func applyDefaultSleepTimerIfNeeded() {
        let mins = settings.defaultSleepTimerMinutes
        guard mins > 0, sleepTimerRemaining == nil else { return }
        startSleepTimer(minutes: mins)
    }

    private func applyVolume(to player: AVPlayer) {
        player.volume = isMuted ? 0 : Float(volume)
    }

    func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
            sceneVideoPlayer?.pause()
            if let content = currentContent {
                AnalyticsService.logPlaybackPaused(contentId: content.id, category: content.category)
            }
        } else {
            audioPlayer?.play()
            sceneVideoPlayer?.play()
            if let content = currentContent {
                AnalyticsService.logPlaybackResumed(contentId: content.id, category: content.category)
            }
        }
        isPlaying.toggle()
        showControls()
    }

    func showControls() {
        controlsVisible = true
        controlsHideTask?.cancel()
        let delay = settings.controlsAutoHideSeconds
        guard delay > 0 else { return }
        controlsHideTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { self.controlsVisible = false }
        }
    }

    func toggleFavorite() {
        switch currentContent {
        case .scene(let scene):
            settings.toggleFavoriteScene(scene.id)
            isFavorite = settings.isFavoriteScene(scene.id)
        case .audioOnly(let item):
            settings.toggleFavoriteAudio(item.id)
            isFavorite = settings.isFavoriteAudio(item.id)
        case nil:
            break
        }
        showControls()
    }

    func startSleepTimer(minutes: Int) {
        selectedSleepTimerMinutes = minutes
        sleepTimerTotal = TimeInterval(minutes * 60)
        sleepTimerStarted = Date()
        sleepTimerRemaining = sleepTimerTotal
        sleepTimerTask?.cancel()
        sleepTimerTask = Task {
            while true {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let started = self.sleepTimerStarted else { return }
                    let elapsed = Date().timeIntervalSince(started)
                    let remaining = max(0, self.sleepTimerTotal - elapsed)
                    self.sleepTimerRemaining = remaining
                    if remaining <= 0 {
                        self.sleepTimerTask?.cancel()
                        self.audioPlayer?.pause()
                        self.sceneVideoPlayer?.pause()
                        self.isPlaying = false
                        self.onSleepTimerExpired?()
                    }
                }
            }
        }
        AnalyticsService.logSleepTimerStarted(durationMinutes: minutes)
        showControls()
    }

    func cancelSleepTimer() {
        sleepTimerTask?.cancel()
        sleepTimerRemaining = nil
        selectedSleepTimerMinutes = nil
        sleepTimerStarted = nil
    }

    func cleanup() {
        audioPlayer?.pause()
        sceneVideoPlayer?.pause()
        stopAudioLoopObserver()
        controlsHideTask?.cancel()
        sleepTimerTask?.cancel()
        let duration = Int(Date().timeIntervalSince1970 * 1000) - playbackStartMs
        if duration > 0 {
            AnalyticsService.logPlaybackEnded(contentId: currentContent?.id ?? "", sessionDurationMs: duration)
        }
    }

    func sleepTimerLabel() -> String? {
        guard let remaining = sleepTimerRemaining, remaining > 0 else { return nil }
        let mins = Int(remaining) / 60
        let secs = Int(remaining) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func installAudioLoopObserver(for player: AVPlayer) {
        stopAudioLoopObserver()
        audioLoopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }

    private func stopAudioLoopObserver() {
        if let observer = audioLoopObserver {
            NotificationCenter.default.removeObserver(observer)
            audioLoopObserver = nil
        }
    }
}

extension PlaybackContent: Identifiable {
    var id: String {
        switch self {
        case .scene(let s): return s.id
        case .audioOnly(let a): return a.id
        }
    }
}

extension PlaybackContent {
    var name: String {
        switch self {
        case .scene(let s): return s.name
        case .audioOnly(let a): return a.title
        }
    }
    var category: String {
        switch self {
        case .scene(let s): return s.category
        case .audioOnly(let a): return a.category
        }
    }
    var isFree: Bool {
        switch self {
        case .scene(let s): return s.isFree
        case .audioOnly(let a): return a.isFree
        }
    }
}
