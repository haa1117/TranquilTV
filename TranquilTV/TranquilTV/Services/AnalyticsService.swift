import Foundation

// Analytics abstraction — mirrors Android event names
// TODO: Integrate Firebase Analytics for tvOS when adding Firebase SDK
struct AnalyticsService {
    static func logScreenView(_ name: String) {
        log("screen_view", ["screen_name": name])
    }

    static func logSceneTapped(sceneId: String, sceneName: String, category: String, isFree: Bool, section: String) {
        log("scene_tapped", ["scene_id": sceneId, "scene_name": sceneName, "category": category, "is_free": isFree, "section": section])
    }

    static func logPlaybackStarted(contentType: String, contentId: String, contentName: String, category: String, isFree: Bool) {
        log("playback_started", ["content_type": contentType, "content_id": contentId, "content_name": contentName, "category": category, "is_free": isFree])
    }

    static func logPlaybackPaused(contentId: String, category: String) {
        log("playback_paused", ["content_id": contentId, "category": category])
    }

    static func logPlaybackResumed(contentId: String, category: String) {
        log("playback_resumed", ["content_id": contentId, "category": category])
    }

    static func logPlaybackEnded(contentId: String, sessionDurationMs: Int) {
        log("playback_ended", ["content_id": contentId, "session_duration_ms": sessionDurationMs])
    }

    static func logFavoriteToggled(contentId: String, added: Bool) {
        log("favorite_toggled", ["content_id": contentId, "added": added])
    }

    static func logSleepTimerStarted(durationMinutes: Int) {
        log("sleep_timer_started", ["duration_minutes": durationMinutes])
    }

    static func logPaywallView(reason: String) {
        log("paywall_view", ["reason": reason])
    }

    static func logPurchaseAttempt(productId: String) {
        log("purchase_attempt", ["product_id": productId])
    }

    static func logPurchaseSuccess(productId: String) {
        log("purchase_success", ["product_id": productId])
    }

    private static func log(_ event: String, _ params: [String: Any] = [:]) {
        // TODO: Replace with Firebase Analytics call:
        // Analytics.logEvent(event, parameters: params)
        #if DEBUG
        print("[Analytics] \(event): \(params)")
        #endif
    }
}
