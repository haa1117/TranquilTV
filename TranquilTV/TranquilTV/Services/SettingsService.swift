import Foundation
import Combine

class SettingsService: ObservableObject {
    static let shared = SettingsService()

    @Published var isPremium: Bool {
        didSet { UserDefaults.standard.set(isPremium, forKey: Keys.isPremium) }
    }
    @Published var currentThemeType: AppThemeType {
        didSet { UserDefaults.standard.set(currentThemeType.rawValue, forKey: Keys.themeType) }
    }
    @Published var defaultVolume: Double {
        didSet { UserDefaults.standard.set(defaultVolume, forKey: Keys.defaultVolume) }
    }
    @Published var defaultSleepTimerMinutes: Int {
        didSet { UserDefaults.standard.set(defaultSleepTimerMinutes, forKey: Keys.defaultSleepTimerMinutes) }
    }
    @Published var autoPlayLastScene: Bool {
        didSet { UserDefaults.standard.set(autoPlayLastScene, forKey: Keys.autoPlayLastScene) }
    }
    @Published var favoriteSceneIds: Set<String> {
        didSet {
            let arr = Array(favoriteSceneIds)
            UserDefaults.standard.set(arr, forKey: Keys.favoriteSceneIds)
        }
    }
    @Published var favoriteAudioIds: Set<String> {
        didSet {
            let arr = Array(favoriteAudioIds)
            UserDefaults.standard.set(arr, forKey: Keys.favoriteAudioIds)
        }
    }
    @Published var purchasedProductIds: Set<String> {
        didSet {
            let arr = Array(purchasedProductIds)
            UserDefaults.standard.set(arr, forKey: Keys.purchasedProductIds)
        }
    }
    @Published var lastPlayedContentType: ContentType = .scene
    @Published var lastPlayedSceneId: String?
    @Published var lastPlayedAudioOnlyId: String?

    var currentTheme: AppTheme { AppTheme.theme(for: currentThemeType) }

    private enum Keys {
        static let isPremium = "isPremium"
        static let themeType = "themeType"
        static let defaultVolume = "defaultVolume"
        static let defaultSleepTimerMinutes = "defaultSleepTimerMinutes"
        static let autoPlayLastScene = "autoPlayLastScene"
        static let favoriteSceneIds = "favoriteSceneIds"
        static let favoriteAudioIds = "favoriteAudioIds"
        static let purchasedProductIds = "purchasedProductIds"
    }

    private init() {
        let defaults = UserDefaults.standard
        isPremium = defaults.bool(forKey: Keys.isPremium)
        let themeRaw = defaults.string(forKey: Keys.themeType) ?? AppThemeType.defaultTheme.rawValue
        currentThemeType = AppThemeType(rawValue: themeRaw) ?? .defaultTheme
        defaultVolume = defaults.object(forKey: Keys.defaultVolume) as? Double ?? 0.8
        defaultSleepTimerMinutes = defaults.object(forKey: Keys.defaultSleepTimerMinutes) as? Int ?? 30
        autoPlayLastScene = defaults.bool(forKey: Keys.autoPlayLastScene)
        let favScenes = defaults.array(forKey: Keys.favoriteSceneIds) as? [String] ?? []
        favoriteSceneIds = Set(favScenes)
        let favAudio = defaults.array(forKey: Keys.favoriteAudioIds) as? [String] ?? []
        favoriteAudioIds = Set(favAudio)
        let purchased = defaults.array(forKey: Keys.purchasedProductIds) as? [String] ?? []
        purchasedProductIds = Set(purchased)
    }

    func toggleFavoriteScene(_ id: String) {
        if favoriteSceneIds.contains(id) {
            favoriteSceneIds.remove(id)
        } else {
            favoriteSceneIds.insert(id)
        }
    }

    func toggleFavoriteAudio(_ id: String) {
        if favoriteAudioIds.contains(id) {
            favoriteAudioIds.remove(id)
        } else {
            favoriteAudioIds.insert(id)
        }
    }

    func isFavoriteScene(_ id: String) -> Bool { favoriteSceneIds.contains(id) }
    func isFavoriteAudio(_ id: String) -> Bool { favoriteAudioIds.contains(id) }

    func canAccessScene(_ scene: Scene) -> Bool {
        if scene.isFree { return true }
        if isPremium { return true }
        if scene.isPurchased { return true }
        if let pid = oneTimeProductForSceneCategory(scene.category) {
            return purchasedProductIds.contains(pid)
        }
        return false
    }

    func canAccessAudio(_ item: AudioOnlyItem) -> Bool {
        if item.isFree { return true }
        if isPremium { return true }
        if let pid = oneTimeProductForAudioTitle(item.title) {
            return purchasedProductIds.contains(pid)
        }
        return false
    }

    func oneTimeProductForSceneCategory(_ category: String) -> String? {
        switch category {
        case "First Snow": return "scene_first_snow"
        case "Focus & Flow": return "focus_flow"
        case "Grounding & Stability": return "grounding_stability"
        case "Anxiety Relief": return "anxiety_relief"
        case "Japanese Forest Paths": return "japanese_forrest"
        case "Mountain & Highlands Calm": return "mountains_calm"
        default: return nil
        }
    }

    func oneTimeProductForAudioTitle(_ title: String) -> String? {
        switch title {
        case "Wind Chimes": return "audio_wind_chimes"
        case "Distant Thunder": return "distant_thunder"
        case "Crackling Campfire": return "crackling_campfire"
        default: return nil
        }
    }

    func setPurchased(_ productId: String) {
        purchasedProductIds.insert(productId)
        if productId == StoreKitService.subscriptionProductId {
            isPremium = true
        }
    }
}
