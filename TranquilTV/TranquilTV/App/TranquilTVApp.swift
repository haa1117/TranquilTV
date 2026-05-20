import SwiftUI

@main
struct TranquilTVApp: App {
    @StateObject private var storeKit = StoreKitService.shared
    @ObservedObject private var settings = SettingsService.shared

    init() {
        // Configure audio session for background playback
        configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(settings)
        }
    }

    private func configureAudioSession() {
        // AVAudioSession is not available on tvOS the same way;
        // ambient audio plays through the TV speaker automatically.
        // Background audio is handled by AVPlayer naturally.
    }
}
