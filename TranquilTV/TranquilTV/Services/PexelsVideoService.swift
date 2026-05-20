import Foundation

// Pexels API service for fetching video URLs by ID
// TODO: Set your Pexels API key in the constant below
class PexelsVideoService {
    static let shared = PexelsVideoService()
    // TODO: Replace with your actual Pexels API key from https://www.pexels.com/api/
    private let apiKey = "YOUR_PEXELS_API_KEY"
    private let baseURL = "https://api.pexels.com/videos/videos/"
    private var cache: [Int: [URL]] = [:]

    private init() {}

    func videoURLs(forId id: Int) async throws -> [URL] {
        if let cached = cache[id] { return cached }

        guard apiKey != "YOUR_PEXELS_API_KEY" else {
            throw PexelsError.noApiKey
        }

        var request = URLRequest(url: URL(string: "\(baseURL)\(id)")!)
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw PexelsError.badResponse
        }
        let json = try JSONDecoder().decode(PexelsVideoResponse.self, from: data)
        let urls = json.videoFiles
            .filter { $0.quality == "hd" || $0.quality == "fhd" }
            .compactMap { URL(string: $0.link) }
        cache[id] = urls
        return urls
    }

    enum PexelsError: Error {
        case noApiKey
        case badResponse
    }
}

private struct PexelsVideoResponse: Decodable {
    let videoFiles: [VideoFile]
    enum CodingKeys: String, CodingKey { case videoFiles = "video_files" }
}

private struct VideoFile: Decodable {
    let link: String
    let quality: String
}
