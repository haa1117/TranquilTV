import Foundation

// Parses videourls.txt and returns Pexels video IDs per category
class VideoPlaylistService {
    static let shared = VideoPlaylistService()
    private var categoryMap: [String: [Int]] = [:]
    private var loaded = false

    private init() {}

    func loadCategoryMap() -> [String: [Int]] {
        if loaded { return categoryMap }
        guard let url = Bundle.main.url(forResource: "videourls", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }
        var current: String?
        var ids: [Int] = []
        for rawLine in content.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if line.hasPrefix("- https://www.pexels.com/video/") {
                if let id = extractPexelsId(from: line) {
                    ids.append(id)
                }
            } else {
                if let key = current, !ids.isEmpty {
                    categoryMap[key] = ids
                }
                current = line
                ids = []
            }
        }
        if let key = current, !ids.isEmpty {
            categoryMap[key] = ids
        }
        loaded = true
        return categoryMap
    }

    func videoIds(forCategory category: String) -> [Int] {
        let map = loadCategoryMap()
        if let direct = map[category] { return direct }
        // Case-insensitive fallback
        let lower = category.lowercased()
        for (key, val) in map {
            if key.lowercased() == lower { return val }
        }
        return []
    }

    private func extractPexelsId(from line: String) -> Int? {
        // Format: - https://www.pexels.com/video/some-title-12345678/
        guard let url = line.dropFirst(2).trimmingCharacters(in: .whitespaces).components(separatedBy: "/").last.flatMap(URL.init(string:)) ?? URL(string: line.dropFirst(2).trimmingCharacters(in: .whitespaces)) else { return nil }
        let parts = line.components(separatedBy: "/")
        // Last non-empty part before trailing slash is "title-ID"
        let segments = parts.filter { !$0.isEmpty }
        if let last = segments.last, let id = last.components(separatedBy: "-").last.flatMap(Int.init) {
            return id
        }
        return nil
    }
}
