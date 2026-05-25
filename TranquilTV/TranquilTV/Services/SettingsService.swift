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
    @Published var audioOnlyMode: Bool {
        didSet { UserDefaults.standard.set(audioOnlyMode, forKey: Keys.audioOnlyMode) }
    }
    /// Seconds before playback controls auto-hide (0 = never hide). Matches Android 3s default.
    @Published var controlsAutoHideSeconds: Int {
        didSet { UserDefaults.standard.set(controlsAutoHideSeconds, forKey: Keys.controlsAutoHideSeconds) }
    }
    @Published var favoriteSceneIds: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(favoriteSceneIds), forKey: Keys.favoriteSceneIds)
        }
    }
    @Published var favoriteAudioIds: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(favoriteAudioIds), forKey: Keys.favoriteAudioIds)
        }
    }
    @Published var purchasedProductIds: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(purchasedProductIds), forKey: Keys.purchasedProductIds)
        }
    }
    @Published var timeBasedSuggestionsEnabled: Bool {
        didSet { UserDefaults.standard.set(timeBasedSuggestionsEnabled, forKey: Keys.timeBasedSuggestionsEnabled) }
    }
    @Published var scheduledMoodsEnabled: Bool {
        didSet { UserDefaults.standard.set(scheduledMoodsEnabled, forKey: Keys.scheduledMoodsEnabled) }
    }
    @Published var scheduledMoodBlocks: [ScheduledMoodBlockData] {
        didSet { persistScheduledBlocks() }
    }
    @Published var lastPlayedContentType: ContentType {
        didSet { UserDefaults.standard.set(lastPlayedContentType == .scene ? "scene" : "audioOnly", forKey: Keys.lastPlayedContentType) }
    }
    @Published var lastPlayedSceneId: String? {
        didSet { UserDefaults.standard.set(lastPlayedSceneId, forKey: Keys.lastPlayedSceneId) }
    }
    @Published var lastPlayedAudioOnlyId: String? {
        didSet { UserDefaults.standard.set(lastPlayedAudioOnlyId, forKey: Keys.lastPlayedAudioOnlyId) }
    }

    var currentTheme: AppTheme { AppTheme.theme(for: currentThemeType) }

    private enum Keys {
        static let isPremium = "isPremium"
        static let themeType = "themeType"
        static let defaultVolume = "defaultVolume"
        static let defaultSleepTimerMinutes = "defaultSleepTimerMinutes"
        static let autoPlayLastScene = "autoPlayLastScene"
        static let audioOnlyMode = "audioOnlyMode"
        static let controlsAutoHideSeconds = "controlsAutoHideSeconds"
        static let favoriteSceneIds = "favoriteSceneIds"
        static let favoriteAudioIds = "favoriteAudioIds"
        static let purchasedProductIds = "purchasedProductIds"
        static let timeBasedSuggestionsEnabled = "timeBasedSuggestionsEnabled"
        static let scheduledMoodsEnabled = "scheduledMoodsEnabled"
        static let scheduledMoodBlocks = "scheduledMoodBlocks"
        static let lastPlayedContentType = "lastPlayedContentType"
        static let lastPlayedSceneId = "lastPlayedSceneId"
        static let lastPlayedAudioOnlyId = "lastPlayedAudioOnlyId"
        static let packSelectedCategories = "packSelectedCategories"
    }

    /// packId → selected category ids (Android `PackService.setSelectedCategories`)
    private var packCategorySelections: [String: [String]] {
        didSet {
            if let data = try? JSONEncoder().encode(packCategorySelections) {
                UserDefaults.standard.set(data, forKey: Keys.packSelectedCategories)
            }
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        isPremium = defaults.bool(forKey: Keys.isPremium)
        let themeRaw = defaults.string(forKey: Keys.themeType) ?? AppThemeType.defaultTheme.rawValue
        currentThemeType = AppThemeType(rawValue: themeRaw) ?? .defaultTheme
        defaultVolume = defaults.object(forKey: Keys.defaultVolume) as? Double ?? 0.8
        defaultSleepTimerMinutes = defaults.object(forKey: Keys.defaultSleepTimerMinutes) as? Int ?? 30
        autoPlayLastScene = defaults.bool(forKey: Keys.autoPlayLastScene)
        audioOnlyMode = defaults.bool(forKey: Keys.audioOnlyMode)
        controlsAutoHideSeconds = defaults.object(forKey: Keys.controlsAutoHideSeconds) as? Int ?? 3
        favoriteSceneIds = Set(defaults.array(forKey: Keys.favoriteSceneIds) as? [String] ?? [])
        favoriteAudioIds = Set(defaults.array(forKey: Keys.favoriteAudioIds) as? [String] ?? [])
        purchasedProductIds = Set(defaults.array(forKey: Keys.purchasedProductIds) as? [String] ?? [])
        timeBasedSuggestionsEnabled = defaults.object(forKey: Keys.timeBasedSuggestionsEnabled) as? Bool ?? true
        scheduledMoodsEnabled = defaults.bool(forKey: Keys.scheduledMoodsEnabled)
        scheduledMoodBlocks = Self.loadScheduledBlocks(from: defaults)
        let contentTypeRaw = defaults.string(forKey: Keys.lastPlayedContentType) ?? "scene"
        lastPlayedContentType = contentTypeRaw == "audioOnly" ? .audioOnly : .scene
        lastPlayedSceneId = defaults.string(forKey: Keys.lastPlayedSceneId)
        lastPlayedAudioOnlyId = defaults.string(forKey: Keys.lastPlayedAudioOnlyId)
        if let data = defaults.data(forKey: Keys.packSelectedCategories),
           let map = try? JSONDecoder().decode([String: [String]].self, from: data) {
            packCategorySelections = map
        } else {
            packCategorySelections = [:]
        }
    }

    private static func loadScheduledBlocks(from defaults: UserDefaults) -> [ScheduledMoodBlockData] {
        guard let data = defaults.data(forKey: Keys.scheduledMoodBlocks),
              let blocks = try? JSONDecoder().decode([ScheduledMoodBlockData].self, from: data),
              !blocks.isEmpty else {
            return ScheduledMoodsService.defaultBlocks()
        }
        return blocks
    }

    private func persistScheduledBlocks() {
        if let data = try? JSONEncoder().encode(scheduledMoodBlocks) {
            UserDefaults.standard.set(data, forKey: Keys.scheduledMoodBlocks)
        }
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
        if isPackCategoryUnlocked(scene.category) { return true }
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

    func isPackPurchased(_ pack: PackDefinition) -> Bool {
        if pack.isFree { return true }
        guard let productId = pack.productId else { return false }
        return purchasedProductIds.contains(productId)
    }

    func isPackCategoryUnlocked(_ sceneCategory: String) -> Bool {
        for pack in PackService.allPacks {
            if pack.isFree {
                if pack.categories.contains(where: { $0.sceneCategory == sceneCategory }) {
                    return true
                }
                continue
            }
            guard isPackPurchased(pack) else { continue }
            let selected = selectedCategories(for: pack.id)
            let ids = selected.isEmpty ? pack.categories.map(\.id) : selected
            for catId in ids {
                if pack.categories.first(where: { $0.id == catId })?.sceneCategory == sceneCategory {
                    return true
                }
            }
        }
        return false
    }

    func selectedCategories(for packId: String) -> [String] {
        packCategorySelections[packId] ?? []
    }

    func setPurchasedPack(_ pack: PackDefinition, categoryIds: [String]? = nil) {
        guard let productId = pack.productId else { return }
        purchasedProductIds.insert(productId)
        let ids = categoryIds ?? pack.categories.map(\.id)
        packCategorySelections[pack.id] = ids
    }

    func oneTimeProductForSceneCategory(_ category: String) -> String? {
        IAPProductCatalog.oneTimeProductForSceneCategory(category)
    }

    func oneTimeProductForAudioTitle(_ title: String) -> String? {
        IAPProductCatalog.oneTimeProductForAudioTitle(title)
    }

    @MainActor
    func setPurchased(_ productId: String) {
        purchasedProductIds.insert(productId)
        if productId == IAPProductCatalog.subscriptionProductId {
            isPremium = true
            return
        }
        if let pack = PackService.allPacks.first(where: { $0.productId == productId }) {
            setPurchasedPack(pack)
        }
    }
}
