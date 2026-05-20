# Tranquil — tvOS App

A native SwiftUI Apple TV app ported from the Flutter Android TV app. Built for tvOS 17.0+, using `AVPlayer`, StoreKit 2, and the native tvOS focus engine.

---

## Requirements

| Tool | Minimum Version |
|---|---|
| Xcode | 15.2 |
| tvOS SDK | 17.0 |
| Swift | 5.9 |
| macOS | 14.0 (Sonoma) |
| Apple Developer account | Required for device deployment |

---

## Opening in Xcode

```bash
open tvos/TranquilTV/TranquilTV.xcodeproj
```

Or double-click `TranquilTV.xcodeproj` in Finder.

---

## Running on Apple TV Simulator

1. Open `TranquilTV.xcodeproj` in Xcode.
2. Select the **TranquilTV** scheme from the scheme picker (top toolbar).
3. Choose an Apple TV simulator from the device picker, e.g. **Apple TV 4K (3rd generation)**.
4. Press **⌘R** (or Product → Run).

The simulator launches the app. Use the on-screen remote or keyboard shortcuts:
- Arrow keys → D-pad navigation
- Return/Enter → Select
- Escape → Menu/Back

---

## Running on a Physical Apple TV

1. Connect your Apple TV to the same Wi-Fi network as your Mac (for wireless pairing) or via USB-C cable.
2. In Xcode → Devices and Simulators, pair your Apple TV.
3. Set your Development Team in Xcode → Targets → TranquilTV → Signing & Capabilities.
4. Select the physical Apple TV as the run destination.
5. Press **⌘R**.

---

## Configuration Required Before First Run

### 1. Pexels API Key

Open [Services/PexelsVideoService.swift](TranquilTV/TranquilTV/Services/PexelsVideoService.swift) and replace the placeholder:

```swift
// TODO: Replace with your Pexels API key from https://www.pexels.com/api/
private let apiKey = "YOUR_PEXELS_API_KEY"
```

Without this key, the app falls back to the bundled `fallback_pexels_3571264.mp4` video for all scenes. The app will not crash.

### 2. Fallback Video

Ensure `fallback_pexels_3571264.mp4` is added to the Xcode project as a bundle resource:

1. Download a nature video from Pexels (video ID 3571264 is a good default).
2. Drag it into the Xcode project under `Resources/`.
3. Make sure **Add to target: TranquilTV** is checked.

### 3. StoreKit — App Store Connect Setup

Before testing real purchases:

1. Create a new tvOS app in [App Store Connect](https://appstoreconnect.apple.com) with bundle ID `co.futurewatch.TranquilTV`.
2. Add the following In-App Purchases:

| Product Name | Type | Product ID |
|---|---|---|
| Tranquil Premium Monthly | Auto-Renewable Subscription | `tranquil_premium_monthly` |
| Nature Scenes Pack | Non-Consumable | `tranquil_pack_nature` |
| Sleep Sounds Pack | Non-Consumable | `tranquil_pack_sleep` |
| Focus Pack | Non-Consumable | `tranquil_pack_focus` |
| Tropical Dusk Scene | Non-Consumable | `tranquil_scene_tropical_dusk` |
| Desert Calm Scene | Non-Consumable | `tranquil_scene_desert_calm` |
| Nordic Cabins Scene | Non-Consumable | `tranquil_scene_nordic_cabins` |
| Thunderstorm Audio | Non-Consumable | `tranquil_audio_thunderstorm` |
| Wind Chimes Audio | Non-Consumable | `tranquil_audio_windchimes` |

3. Create a **Sandbox Tester** account in App Store Connect → Users and Access → Sandbox.
4. Sign in with the sandbox account on the Apple TV (Settings → Accounts → iTunes and App Store).

**StoreKit Local Testing (no App Store Connect needed):**

The project includes a `Products.storekit` configuration file at `TranquilTV/Resources/Products.storekit`. To use it during development:

1. In Xcode, select the **TranquilTV** scheme → Edit Scheme.
2. Under **Run → Options**, set **StoreKit Configuration** to `Products.storekit`.
3. This lets you test purchases without an App Store Connect account.

### 4. Firebase Analytics (Optional)

Analytics currently logs to the Xcode console in DEBUG mode only. To enable Firebase:

1. Add Firebase iOS SDK via Swift Package Manager:
   - File → Add Package Dependencies → `https://github.com/firebase/firebase-ios-sdk`
   - Add `FirebaseAnalytics` product to the TranquilTV target.
2. Download `GoogleService-Info.plist` from the Firebase console and drag it into the Xcode project.
3. Open [Services/AnalyticsService.swift](TranquilTV/TranquilTV/Services/AnalyticsService.swift) and replace the `print` statements with `Analytics.logEvent(...)` calls.
4. In [App/TranquilTVApp.swift](TranquilTV/TranquilTV/App/TranquilTVApp.swift), add `FirebaseApp.configure()` as the first line of `init()`.

### 5. Firebase Crashlytics (Optional)

1. Add `FirebaseCrashlytics` SPM product to the target.
2. Add a **Run Script** build phase (after Compile Sources):
   ```
   "${BUILD_DIR%Build/*}SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
   ```
3. Call `FirebaseApp.configure()` in `TranquilTVApp.init()` (same as Analytics).

---

## Project Structure

```
tvos/
├── README.md                        ← this file
├── docs/
│   └── tvos-migration-plan.md       ← full migration analysis
└── TranquilTV/
    ├── TranquilTV.xcodeproj/
    └── TranquilTV/
        ├── App/
        │   ├── TranquilTVApp.swift   ← @main entry point
        │   └── Info.plist
        ├── Models/
        │   ├── Scene.swift
        │   ├── AudioOnlyItem.swift
        │   └── AppTheme.swift
        ├── Services/
        │   ├── SceneService.swift
        │   ├── AudioOnlyService.swift
        │   ├── SettingsService.swift
        │   ├── PexelsVideoService.swift
        │   ├── VideoPlaylistService.swift
        │   ├── StoreKitService.swift
        │   └── AnalyticsService.swift
        ├── ViewModels/
        │   ├── HomeViewModel.swift
        │   └── PlaybackViewModel.swift
        ├── Screens/
        │   ├── SplashScreen.swift
        │   ├── HomeScreen.swift
        │   ├── PlaybackScreen.swift
        │   ├── SettingsScreen.swift
        │   └── PaywallScreen.swift
        ├── Components/
        │   ├── SceneCardView.swift
        │   ├── FocusableButton.swift
        │   └── AppHeaderView.swift
        ├── Theme/
        │   └── TranquilTheme.swift
        ├── Extensions/
        │   └── Color+Hex.swift
        ├── Assets.xcassets/          ← all app images + app icon
        └── Resources/
            ├── audio/                ← 6 .mp3 files
            ├── images/               ← scene thumbnails
            └── videourls.txt         ← Pexels video ID map
```

---

## Key Differences from Android TV Version

| Feature | Android TV | tvOS |
|---|---|---|
| Ads | Unity Ads | None (policy; premium only) |
| Focus | `FocusNode` (Flutter) | Native tvOS focus engine |
| IAP | `flutter_inapp_purchase` | StoreKit 2 |
| Video | ExoPlayer (via plugin) | `AVQueuePlayer` |
| Analytics | Firebase (direct) | `AnalyticsService` abstraction |
| Infatica | Integrated | Removed (no tvOS SDK) |
| Navigation | `go_router` | `NavigationStack` typed path |

See [docs/tvos-migration-plan.md](docs/tvos-migration-plan.md) for the full analysis.

---

## Known TODOs

- [ ] Replace `"YOUR_PEXELS_API_KEY"` in `PexelsVideoService.swift`
- [ ] Add `fallback_pexels_3571264.mp4` to Resources
- [ ] Create App Store Connect app + IAP products
- [ ] Wire Firebase Analytics (`AnalyticsService.swift`)
- [ ] Wire Firebase Crashlytics
- [ ] Set Development Team in Xcode Signing settings
- [ ] Add `Products.storekit` file for local StoreKit testing (Xcode 15)
