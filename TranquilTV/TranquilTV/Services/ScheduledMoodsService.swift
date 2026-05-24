import Foundation

/// Mood categories aligned with Android `ScheduledMoodCategory`.
enum ScheduledMoodCategory: String, CaseIterable, Codable {
    case forestNature = "Forest / Nature"
    case fireplaceCozy = "Fireplace / Cozy"
    case urbanRain = "Urban Rain"
    case sleepDark = "Sleep / Dark ambience"
    case lightCityFocus = "Light City / Focus"

    var sceneCategory: String {
        switch self {
        case .forestNature: return "Grounding & Stability"
        case .fireplaceCozy: return "Candlelight & Fire Glow"
        case .urbanRain: return "Window Views"
        case .sleepDark: return "Night Horizons"
        case .lightCityFocus: return "Focus & Flow"
        }
    }

    var icon: String {
        switch self {
        case .forestNature: return "leaf.fill"
        case .fireplaceCozy: return "flame.fill"
        case .urbanRain: return "cloud.rain.fill"
        case .sleepDark: return "moon.fill"
        case .lightCityFocus: return "brain.head.profile"
        }
    }
}

struct ScheduledMoodBlockData: Identifiable, Codable, Hashable {
    var id: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var moodCategory: ScheduledMoodCategory

    var timeRangeLabel: String {
        "\(Self.formatHour(startHour, minute: startMinute)) – \(Self.formatHour(endHour, minute: endMinute))"
    }

    func contains(hour: Int, minute: Int) -> Bool {
        let startM = startHour * 60 + startMinute
        let endM = endHour * 60 + endMinute
        let nowM = hour * 60 + minute
        if startM <= endM {
            return nowM >= startM && nowM < endM
        }
        return nowM >= startM || nowM < endM
    }

    private static func formatHour(_ h: Int, minute: Int) -> String {
        let suffix = h < 12 ? "AM" : "PM"
        let display = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        if minute == 0 {
            return "\(display) \(suffix)"
        }
        return String(format: "%d:%02d %@", display, minute, suffix)
    }
}

enum ScheduledMoodsService {
    static let maxBlocks = 4

    static func defaultBlocks() -> [ScheduledMoodBlockData] {
        [
            ScheduledMoodBlockData(
                id: "morning", startHour: 6, startMinute: 0,
                endHour: 12, endMinute: 0, moodCategory: .lightCityFocus
            ),
            ScheduledMoodBlockData(
                id: "afternoon", startHour: 12, startMinute: 0,
                endHour: 17, endMinute: 0, moodCategory: .forestNature
            ),
            ScheduledMoodBlockData(
                id: "evening", startHour: 17, startMinute: 0,
                endHour: 21, endMinute: 0, moodCategory: .fireplaceCozy
            ),
            ScheduledMoodBlockData(
                id: "night", startHour: 21, startMinute: 0,
                endHour: 6, endMinute: 0, moodCategory: .sleepDark
            ),
        ]
    }

    static func moodSceneCategory(forNow blocks: [ScheduledMoodBlockData]) -> String? {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let minute = Calendar.current.component(.minute, from: now)
        for block in blocks where block.contains(hour: hour, minute: minute) {
            return block.moodCategory.sceneCategory
        }
        return nil
    }
}
