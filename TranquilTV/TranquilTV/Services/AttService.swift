import AppTrackingTransparency
import Foundation

/// App Tracking Transparency (tvOS 14+).
/// Request once after the first UI frame, before analytics or ad SDK initialization.
@MainActor
enum AttService {
    private static var requested = false

    static func requestPermissionIfNeeded() async {
        guard !requested else { return }
        requested = true

        let status = ATTrackingManager.trackingAuthorizationStatus
        guard status == .notDetermined else { return }

        // Brief delay so splash UI is visible before the system dialog.
        try? await Task.sleep(for: .milliseconds(300))

        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { _ in
                continuation.resume()
            }
        }
    }
}
