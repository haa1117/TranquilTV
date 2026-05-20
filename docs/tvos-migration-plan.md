# Tranquil tvOS Migration Plan

## Overview

This document describes the architecture, decisions, and component mapping for the Tranquil tvOS app — a native SwiftUI port of the Flutter-based Android TV app.

**Source:** Flutter/Dart Android TV app at `/` (project root)
**Target:** SwiftUI tvOS 17.0+ app at `/tvos/TranquilTV/`
**Bundle ID:** `co.futurewatch.TranquilTV`

---

## Architecture Mapping

| Android TV (Flutter) | tvOS (SwiftUI) | Notes |
|---|---|---|
| `StatefulWidget` / `StatelessWidget` | `View` + `@State` / `@Binding` | Standard SwiftUI patterns |
| `Provider` / `ChangeNotifier` | `ObservableObject` + `@StateObject` / `@EnvironmentObject` | Reactive state via Combine |
| `Navigator.push` / `pop` | `NavigationStack(path:)` with typed `NavigationPath` | Type-safe push navigation |
| `FocusNode` / `autofocus` | `@Environment(\.isFocused)` + `@FocusState` | Native tvOS focus engine |
| `SharedPreferences` | `UserDefaults` | Same semantics |
| `flutter_inapp_purchase` | StoreKit 2 (`Product`, `Transaction`) | Modern async/await API |
| `firebase_analytics` | `AnalyticsService` abstraction | TODO: wire Firebase SDK |
| `firebase_crashlytics` | Not integrated | TODO: add CrashReporter |
| `unity_ads` | **Omitted** | Not available on tvOS; policy-safe |
| `video_player` (Pexels) | `AVQueuePlayer` + `AVPlayerLooper` | Hardware-accelerated |
| `just_audio` | `AVAudioPlayer` via `AVPlayer` | Single audio session |

---

## Screen Mapping

| Flutter Screen | tvOS Screen | File |
|---|---|---|
| `home_screen.dart` | `HomeScreen` | `Screens/HomeScreen.swift` |
| `playback_screen.dart` | `PlaybackScreen` | `Screens/PlaybackScreen.swift` |
| `settings_screen.dart` | `SettingsScreen` | `Screens/SettingsScreen.swift` |
| `about_settings_page.dart` | `AboutSettingsPage` | `Screens/SettingsScreen.swift` |
| `theme_settings_page.dart` | `ThemeSettingsPage` | `Screens/SettingsScreen.swift` |
| N/A (audio slider in settings) | `AudioSettingsPage` | `Screens/SettingsScreen.swift` |
| N/A (sleep timer inline) | `SleepTimerSettingsPage` | `Screens/SettingsScreen.swift` |
| IAP paywall (inline) | `PaywallScreen` | `Screens/PaywallScreen.swift` |
| Splash / loading | `SplashScreen` | `Screens/SplashScreen.swift` |

---

## Service Mapping

| Flutter Service | tvOS Service | Key Difference |
|---|---|---|
| `analytics_service.dart` | `AnalyticsService.swift` | Console-only in debug; TODO: Firebase |
| `settings_service.dart` | `SettingsService.swift` | `@Published` properties for Combine reactivity |
| `infatica_service.dart` | **Removed** | Infatica SDK not available on tvOS |
| `PexelsApi` (inline) | `PexelsVideoService.swift` | Async/await; per-ID response cache |
| In-app purchase (plugin) | `StoreKitService.swift` | StoreKit 2 with transaction listener |
| N/A | `VideoPlaylistService.swift` | Parses `videourls.txt` for Pexels video IDs |

---

## Data Model Mapping

| Flutter Model | tvOS Model | Notes |
|---|---|---|
| `Scene` (inline map) | `Scene.swift` | `Identifiable`, `Hashable`, `Codable` |
| Audio items (inline list) | `AudioOnlyItem.swift` | Includes `ContentType` enum |
| Theme (inline enum) | `AppTheme.swift` + `AppThemeType` | 5 themes; gradient + accent colors |

---

## Content Inventory

### Scenes (23 total)

**Free (8):**
1. Rain Forest Ambiance
2. Ocean At Night
3. City Rain
4. Soft Clouds
5. Autumn Leaves
6. Mountain & Highlands Calm
7. Desert Nights
8. Window Views

**Premium (15):**
1. Crackling Campfire
2. Distant Thunder
3. First Snow
4. Spring Blossoms
5. Japanese Forrest Paths
6. Summer Dusk
7. Nordic Cabins
8. Tropical Dusk
9. Desert & Dunes Calm
10. Floating Balloons
11. Night Horizons
12. Royal Library Fireplace
13. Anxiety Relief
14. Focus and Flow
15. Aquarium Fish

### Audio-Only Items (6 total)

**Free (3):**
- Rain Forest (`rain_forest.mp3`)
- Ocean (`ocean.mp3`)
- City Rain (`city_rain.mp3`)

**Premium (3):**
- Thunderstorm (`thunderstorm.mp3`)
- Crackling Campfire (`campfire.mp3`)
- Wind Chimes (`wind_chimes.mp3`)

---

## IAP Product IDs

| Product | Type | Product ID |
|---|---|---|
| Tranquil Premium Monthly | Auto-renewable subscription | `tranquil_premium_monthly` |
| Nature Scenes Pack | One-time | `tranquil_pack_nature` |
| Sleep Sounds Pack | One-time | `tranquil_pack_sleep` |
| Focus Pack | One-time | `tranquil_pack_focus` |
| Tropical Dusk | One-time | `tranquil_scene_tropical_dusk` |
| Desert Calm | One-time | `tranquil_scene_desert_calm` |
| Nordic Cabins | One-time | `tranquil_scene_nordic_cabins` |
| Rain Forest Audio | One-time (duplicate free — remove) | `tranquil_audio_rainforest` |
| Thunderstorm Audio | One-time | `tranquil_audio_thunderstorm` |
| Wind Chimes Audio | One-time | `tranquil_audio_windchimes` |

> **TODO:** Register all product IDs in App Store Connect under the tvOS app.

---

## Themes

| Theme | Accent Color | Identifier |
|---|---|---|
| Default | `#00BCD4` teal | `.default` |
| Calm Ocean | `#4A90E2` blue | `.calmOcean` |
| Forest Mist | `#6B9F78` green | `.forestMist` |
| Sunset Glow | `#E8A87C` orange | `.sunsetGlow` |
| Night Serenity | `#9B59B6` purple | `.nightSerenity` |

---

## Design Decisions & tvOS Deviations

### Focus Engine
- **Android TV:** Explicit `FocusNode` management + `autofocus: true` via Flutter.
- **tvOS:** Native `@Environment(\.isFocused)` + `.focusable()`. No manual focus tracking needed. The Siri Remote and HDMI-CEC controllers work automatically.
- **Reason:** tvOS focus engine is mandatory — apps that fight it fail App Store review.

### Cards Layout
- **Android TV:** `Row` scrollable horizontal lists with `LazyRow`.
- **tvOS:** `ScrollView(.horizontal)` with `HStack` — identical visual result.
- Card size: 320×180pt (matches Android TV cards scaled for 1920×1080 tvOS canvas).

### Ads
- **Android TV:** Unity Ads banner/interstitial shown to non-premium users.
- **tvOS:** Ads omitted entirely. Apple prohibits video ads in tvOS apps except through Apple's own ad network (which requires a separate integration and minimum traffic thresholds). The premium paywall is the sole monetization path on tvOS.

### Navigation
- **Android TV:** `go_router` with named routes.
- **tvOS:** `NavigationStack` with `PlaybackContent`-typed `NavigationPath`. Type-safe, crash-free, and idiomatic SwiftUI.

### Audio Session
- **Android TV:** `just_audio` plugin handles audio focus.
- **tvOS:** `AVAudioSession.sharedInstance().setCategory(.playback)` is set in `PlaybackViewModel`. This ensures audio continues when the screen dims and respects AirPlay.

### Video Playback
- **Android TV:** `video_player` plugin wrapping ExoPlayer.
- **tvOS:** `AVQueuePlayer` with `AVPlayerLooper` for seamless looping. `CategoryVideoPlayer` class in `PlaybackScreen.swift` fetches Pexels video URLs by category (via `VideoPlaylistService` + `PexelsVideoService`) and falls back to the bundled `fallback_pexels_3571264.mp4` if the API key is missing or the network request fails.

### Infatica (Residential Proxy SDK)
- **Android TV:** `InfaticaManager.kt` / `infatica_service.dart` — background SDK.
- **tvOS:** Removed entirely. Infatica does not have a tvOS/iOS SDK that meets App Store guidelines for background network usage.

---

## Missing Configuration (TODOs)

1. **Pexels API Key** — in `PexelsVideoService.swift`:
   ```swift
   private let apiKey = "YOUR_PEXELS_API_KEY"
   ```
   Replace with a real key from [pexels.com/api](https://www.pexels.com/api/).

2. **StoreKit Product IDs** — in `StoreKitService.swift`:
   ```swift
   private let productIds: Set<String> = [...]
   ```
   Must match exactly what is configured in App Store Connect.

3. **Firebase Analytics** — in `AnalyticsService.swift`:
   Add `firebase_ios_sdk` via Swift Package Manager and replace `print` calls with `Analytics.logEvent(...)`.

4. **Firebase Crashlytics** — Not yet integrated. Add `FirebaseCrashlytics` SPM package and call `FirebaseApp.configure()` in `TranquilTVApp.swift`.

5. **App Store Connect** — Create a new tvOS app with bundle ID `co.futurewatch.TranquilTV`. Add all IAP product IDs listed above.

6. **Signing** — Set your Apple Developer Team ID in Xcode → Signing & Capabilities. `CODE_SIGN_STYLE = Automatic`.

7. **Fallback video** — `fallback_pexels_3571264.mp4` must be added to the Xcode project as a bundle resource if not already present. Download from: `https://www.pexels.com/video/3571264/`

---

## Asset Inventory

All Flutter assets have been copied to the tvOS project:

| Flutter Path | tvOS Path |
|---|---|
| `assets/images/*.{jpg,png}` | `Resources/images/` + `Assets.xcassets/*.imageset/` |
| `assets/audio/*.mp3` | `Resources/audio/` |
| `assets/icons/app_logo.png` | `Assets.xcassets/app_logo.imageset/` + `AppIcon.appiconset/` |
| `assets/videourls.txt` | `Resources/videourls.txt` |

---

## Build Requirements

- Xcode 15.2+
- tvOS 17.0 SDK
- Apple Developer Program membership (for device deployment)
- Swift 5.9+

---

## Testing Checklist

- [ ] App launches on Apple TV simulator (tvOS 17.0+)
- [ ] Siri Remote D-pad navigates all cards/buttons without getting stuck
- [ ] Free scenes play video (Pexels or fallback)
- [ ] Premium scenes show lock/paywall prompt
- [ ] Audio-only items play audio
- [ ] Sleep timer counts down and pauses playback
- [ ] Favorites persist across app restarts
- [ ] Theme changes update all screens immediately
- [ ] StoreKit sandbox purchase unlocks premium
- [ ] Restore purchases restores premium state
- [ ] App does not crash when Pexels API key is missing (uses fallback)
