import Foundation

struct Scene: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let description: String
    let thumbnailUrl: String
    let audioUrl: String
    let isPremium: Bool
    let isFree: Bool
    let category: String
    var isPurchased: Bool

    var isLocked: Bool { !isFree && !isPurchased && isPremium }

    var localImageAsset: String? { CategoryAssets.imageName(for: category) }
}

enum CategoryAssets {
    static func imageName(for category: String) -> String? {
        let map: [String: String] = [
            "Travel Without Travel": "Travel without travel",
            "Window Views": "Window Views",
            "Summer Dusk": "Summer Dusk",
            "Spring Blossoms": "Spring Blossoms",
            "Desert Nights": "Desert Nights",
            "Tropical Dusk": "Tropical Dusk",
            "Floating Balloons": "Floating Balloons",
            "Aquarium Fish": "Aquarium Fish",
            "Focus & Flow": "Focus and Flow",
            "Grounding & Stability": "Grounded and stability",
            "Anxiety Relief": "Anxiety Relief",
            "Japanese Forest Paths": "Japanese Forrest Paths",
            "Autumn Leaves": "Autumn Leaves",
            "First Snow": "First Snow",
            "Mountain & Highlands Calm": "Mountain & Highlands Calm",
            "Water Worlds": "Water Worlds",
            "Desert & Dunes Calm": "Desert & Dunes Calm",
            "Night Horizons": "Night Horizons",
            "Candlelight & Fire Glow": "Candlelight & Fire Glow",
            "Nordic Cabins": "Nordic Cabins",
            "Counting Sheep": "Counting Sheep",
            "Soft Clouds": "Soft Clouds",
            "Royal Library Fireplace": "Royal Library Fireplace",
        ]
        return map[category]
    }
}
