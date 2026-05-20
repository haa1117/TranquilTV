import Foundation

enum ContentType {
    case scene
    case audioOnly
}

struct AudioOnlyItem: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let artworkUrl: String
    let audioSource: String
    let category: String
    let isPremium: Bool
    let isFree: Bool

    var isLocked: Bool { !isFree && isPremium }

    // Local audio asset path
    var localAudioAsset: String? {
        if audioSource.hasPrefix("assets/audio/") {
            return audioSource.replacingOccurrences(of: "assets/audio/", with: "")
        }
        return nil
    }

    // Local image asset for display
    var localImageAsset: String? {
        let map: [String: String] = [
            "Rain Forest Ambience": "Rain Forest Ambiance",
            "Ocean At Night": "Ocean At Night",
            "City Rain": "City Rain",
            "Distant Thunder": "Distant Thunder",
            "Crackling Campfire": "Crackling Campfire",
            "Wind Chimes": "Wind Chimes",
        ]
        return map[title]
    }
}
