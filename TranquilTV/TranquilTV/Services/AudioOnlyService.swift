import Foundation

class AudioOnlyService {
    static let shared = AudioOnlyService()
    private init() {}

    let allItems: [AudioOnlyItem] = [
        AudioOnlyItem(id: "audio_rain_forest_1", title: "Rain Forest Ambience",
                      artworkUrl: "", audioSource: "assets/audio/rain_forest.mp3",
                      category: "Forest", isPremium: false, isFree: true),
        AudioOnlyItem(id: "audio_ocean_night_1", title: "Ocean At Night",
                      artworkUrl: "", audioSource: "assets/audio/ocean.mp3",
                      category: "Ocean", isPremium: false, isFree: true),
        AudioOnlyItem(id: "audio_city_rain_1", title: "City Rain",
                      artworkUrl: "", audioSource: "assets/audio/city_rain.mp3",
                      category: "Rain", isPremium: false, isFree: true),
        AudioOnlyItem(id: "audio_thunder_1", title: "Distant Thunder",
                      artworkUrl: "", audioSource: "assets/audio/thunderstorm.mp3",
                      category: "Rain", isPremium: true, isFree: false),
        AudioOnlyItem(id: "audio_campfire_1", title: "Crackling Campfire",
                      artworkUrl: "", audioSource: "assets/audio/campfire.mp3",
                      category: "Fireplace", isPremium: true, isFree: false),
        AudioOnlyItem(id: "audio_wind_chimes_1", title: "Wind Chimes",
                      artworkUrl: "", audioSource: "assets/audio/wind_chimes.mp3",
                      category: "Ambience", isPremium: true, isFree: false),
    ]

    var freeItems: [AudioOnlyItem] { allItems.filter { $0.isFree } }
    var premiumItems: [AudioOnlyItem] { allItems.filter { $0.isPremium } }

    func item(byId id: String) -> AudioOnlyItem? {
        allItems.first { $0.id == id }
    }
}
