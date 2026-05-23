import Foundation

struct PackCategory {
    let id: String
    let name: String
    let sceneCategory: String
}

struct PackDefinition: Identifiable {
    let id: String
    let name: String
    let productId: String?
    let bundlePrice: Double
    let individualPrice: Double
    let categories: [PackCategory]
    let isFree: Bool

    var priceString: String {
        isFree ? "Free" : String(format: "$%.2f", bundlePrice)
    }

    /// Scene thumbnail assets for pack preview mosaic.
    var previewImageAssets: [String] {
        categories.compactMap { CategoryAssets.imageName(for: $0.sceneCategory) }
    }
}

struct PackService {
    static let natureMode = PackDefinition(
        id: "nature_mode",
        name: "Nature Mode",
        productId: nil,
        bundlePrice: 0,
        individualPrice: 0,
        categories: [
            PackCategory(id: "mountain_highlands", name: "Mountain & Highlands Calm", sceneCategory: "Mountain & Highlands Calm"),
            PackCategory(id: "desert_dunes", name: "Desert & Dunes Calm", sceneCategory: "Desert & Dunes Calm"),
            PackCategory(id: "water_worlds", name: "Water Worlds", sceneCategory: "Water Worlds"),
        ],
        isFree: true
    )

    static let sleepMode = PackDefinition(
        id: "sleep_mode",
        name: "Sleep Mode",
        productId: "pack_sleep_mode",
        bundlePrice: 3.98,
        individualPrice: 1.99,
        categories: [
            PackCategory(id: "night_horizons", name: "Night Horizons", sceneCategory: "Night Horizons"),
            PackCategory(id: "counting_sheep", name: "Counting Sheep", sceneCategory: "Counting Sheep"),
            PackCategory(id: "nordic_cabins", name: "Nordic Cabins", sceneCategory: "Nordic Cabins"),
        ],
        isFree: false
    )

    static let studyPack = PackDefinition(
        id: "study_pack",
        name: "Study Pack",
        productId: "pack_study",
        bundlePrice: 3.98,
        individualPrice: 1.99,
        categories: [
            PackCategory(id: "candlelight", name: "Candlelight & Fire Glow", sceneCategory: "Candlelight & Fire Glow"),
            PackCategory(id: "royal_library", name: "Royal Library Fireplace", sceneCategory: "Royal Library Fireplace"),
            PackCategory(id: "soft_clouds", name: "Soft Clouds", sceneCategory: "Soft Clouds"),
        ],
        isFree: false
    )

    static let calmGrounded = PackDefinition(
        id: "calm_grounded",
        name: "Calm & Grounded",
        productId: "pack_calm_grounded",
        bundlePrice: 3.98,
        individualPrice: 1.99,
        categories: [
            PackCategory(id: "focus_flow", name: "Focus & Flow", sceneCategory: "Focus & Flow"),
            PackCategory(id: "grounding", name: "Grounding & Stability", sceneCategory: "Grounding & Stability"),
            PackCategory(id: "anxiety_relief", name: "Anxiety Relief", sceneCategory: "Anxiety Relief"),
        ],
        isFree: false
    )

    static let natureEscapes = PackDefinition(
        id: "nature_escapes",
        name: "Nature Escapes",
        productId: "pack_nature_escapes",
        bundlePrice: 3.98,
        individualPrice: 1.99,
        categories: [
            PackCategory(id: "japanese_forest", name: "Japanese Forest Paths", sceneCategory: "Japanese Forest Paths"),
            PackCategory(id: "autumn_leaves", name: "Autumn Leaves", sceneCategory: "Autumn Leaves"),
            PackCategory(id: "first_snow", name: "First Snow", sceneCategory: "First Snow"),
        ],
        isFree: false
    )

    static let allPacks: [PackDefinition] = [natureMode, sleepMode, studyPack, calmGrounded, natureEscapes]
}
