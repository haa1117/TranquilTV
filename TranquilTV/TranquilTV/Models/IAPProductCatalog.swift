import Foundation

/// App Store Connect in-app purchase product IDs (Non-Consumable + subscription).
enum IAPProductCatalog {
    static let subscriptionProductId = "tranquil_premium_monthly"

    /// All one-time (non-consumable) product IDs configured in App Store Connect.
    static let oneTimeProductIds: Set<String> = [
        // Scenes
        "scene_first_snow",
        "scene_autumn_leaves",
        "focus_flow",
        "grounding_stability",
        "anxiety_relief",
        "japanese_forrest",
        "mountains_calm",
        // Audio
        "audio_wind_chimes",
        "distant_thunder",
        "crackling_campfire",
        // Bundles / packs
        "pack_sleep_mode",
        "pack_study",
        "pack_calm_grounded",
        "pack_nature_escapes",
    ]

    static var allProductIds: Set<String> {
        var ids = oneTimeProductIds
        ids.insert(subscriptionProductId)
        return ids
    }

    static func displayName(for productId: String) -> String {
        displayNames[productId] ?? productId
    }

    static func oneTimeProductForSceneCategory(_ category: String) -> String? {
        sceneCategoryProducts[category.trimmingCharacters(in: .whitespaces)]
    }

    static func oneTimeProductForAudioTitle(_ title: String) -> String? {
        audioTitleProducts[title.trimmingCharacters(in: .whitespaces)]
    }

    static func isPackProduct(_ productId: String) -> Bool {
        productId.hasPrefix("pack_")
    }

    static func fallbackPrice(for productId: String) -> String {
        fallbackPrices[productId] ?? "$1.99"
    }

    // MARK: - Private maps

    private static let displayNames: [String: String] = [
        subscriptionProductId: "Tranquil Premium Monthly",
        "scene_first_snow": "First Snow",
        "scene_autumn_leaves": "Autumn Leaves",
        "focus_flow": "Focus Flow",
        "grounding_stability": "Grounding Stability",
        "anxiety_relief": "Anxiety Relief",
        "japanese_forrest": "Japanese Forrest",
        "mountains_calm": "Mountains Calm",
        "audio_wind_chimes": "Wind Chimes",
        "distant_thunder": "Distant Thunder",
        "crackling_campfire": "Crackling Fire",
        "pack_sleep_mode": "Sleep Pack",
        "pack_study": "Study Pack",
        "pack_calm_grounded": "Calm and Grounded Pack",
        "pack_nature_escapes": "Nature Escapes Pack",
    ]

    private static let sceneCategoryProducts: [String: String] = [
        "First Snow": "scene_first_snow",
        "Autumn Leaves": "scene_autumn_leaves",
        "Focus & Flow": "focus_flow",
        "Grounding & Stability": "grounding_stability",
        "Anxiety Relief": "anxiety_relief",
        "Japanese Forest Paths": "japanese_forrest",
        "Mountain & Highlands Calm": "mountains_calm",
    ]

    private static let audioTitleProducts: [String: String] = [
        "Wind Chimes": "audio_wind_chimes",
        "Distant Thunder": "distant_thunder",
        "Crackling Campfire": "crackling_campfire",
    ]

    /// Hardcoded fallback prices shown only when StoreKit hasn't loaded live products yet.
    private static let fallbackPrices: [String: String] = [
        "scene_first_snow": "$1.99",
        "scene_autumn_leaves": "$1.99",
        "focus_flow": "$1.99",
        "grounding_stability": "$1.99",
        "anxiety_relief": "$1.99",
        "japanese_forrest": "$1.99",
        "mountains_calm": "$1.99",
        "audio_wind_chimes": "$1.99",
        "distant_thunder": "$1.99",
        "crackling_campfire": "$1.99",
        "pack_sleep_mode": "$3.98",
        "pack_study": "$3.98",
        "pack_calm_grounded": "$3.98",
        "pack_nature_escapes": "$3.98",
        subscriptionProductId: "$4.99",
    ]
}
