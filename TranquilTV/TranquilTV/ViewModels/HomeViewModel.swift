import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var favoriteScenes: [Scene] = []
    @Published var favoriteAudioItems: [AudioOnlyItem] = []

    private let sceneService = SceneService.shared
    private let audioService = AudioOnlyService.shared
    let settings = SettingsService.shared

    var featuredScenes: [Scene] { sceneService.featuredScenes }
    var freeScenes: [Scene] { sceneService.freeScenes }
    var premiumScenes: [Scene] { sceneService.premiumScenes }
    var audioOnlyItems: [AudioOnlyItem] { audioService.allItems }

    var hasAnyFavorites: Bool {
        !favoriteScenes.isEmpty || !favoriteAudioItems.isEmpty
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        settings.$favoriteSceneIds
            .combineLatest(settings.$favoriteAudioIds)
            .receive(on: RunLoop.main)
            .sink { [weak self] (sceneIds, audioIds) in
                guard let self else { return }
                self.favoriteScenes = self.sceneService.allScenes.filter { sceneIds.contains($0.id) }
                self.favoriteAudioItems = self.audioService.allItems.filter { audioIds.contains($0.id) }
            }
            .store(in: &cancellables)
    }

    func canAccess(scene: Scene) -> Bool {
        settings.canAccessScene(scene)
    }

    func canAccess(audio: AudioOnlyItem) -> Bool {
        settings.canAccessAudio(audio)
    }

    func toggleFavorite(scene: Scene) {
        settings.toggleFavoriteScene(scene.id)
        AnalyticsService.logFavoriteToggled(contentId: scene.id, added: !settings.isFavoriteScene(scene.id))
    }

    func toggleFavorite(audio: AudioOnlyItem) {
        settings.toggleFavoriteAudio(audio.id)
    }
}
