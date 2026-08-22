# UrgeAway — Native iOS Migration Report

## 0. Important context this report is written against

The uploaded project is **not** a native-Android-only app. It's a
[Capacitor](https://capacitorjs.com) hybrid app: one shared `www/`
core (HTML/CSS/vanilla JS) that already runs on both Android and iOS,
plus a `build-ios.yml` GitHub Actions workflow that already produces an
unsigned iOS Simulator build of that shared core. Nothing here needed
"finding an iOS equivalent" for basic app plumbing — the original app
already had one.

You asked for a full **native Swift/SwiftUI rewrite anyway**, as a
separate app, understanding that this diverges from the shared
codebase and will need its own ongoing maintenance. That's what's in
`ios/`. The original Capacitor project is preserved unchanged under
`original-capacitor-app/`.

**This build has not been run.** There is no macOS/Xcode available in
the environment that produced this code, so nothing here has been
compiled or tested locally. The GitHub Actions workflow
(`.github/workflows/ios-native.yml`) will do that on first push — see
"Verifying the build" below before trusting any of this.

---

## 1. Android/original-app analysis

- **Framework:** Capacitor 6 wrapping a hand-written vanilla JS SPA
  (no React/Vue/framework) — `www/js/*.js`, `www/css/styles.css`,
  `www/index.html`.
- **Architecture:** a small hash-free router in `app.js` swaps DOM
  screens in and out of `#screen-container`; `storage.js` wraps
  `localStorage`/Capacitor `Preferences` behind a `Storage`/`Data`
  API; `screens.js` renders the five tabs (Home, Activities, Progress,
  Journal, Settings); `flows.js` renders full-screen takeovers
  (splash, login gate, Urge Mode, onboarding); `activities.js` (9
  curated games/exercises) and `distractions.js` (~30 lightweight
  generators used only inside Urge Mode) are separate registries;
  `urgelock.js`, `account.js`, `dashboard.js`, `notifications.js`,
  `push.js` round out auth, notifications, and the timed "Urge Lock"
  feature.
- **Platform-specific handling already present in the source:** the
  app checks `isIOS()` in a few places and already documents, in its
  own comments, that (a) Google Sign-In is Android-only (no iOS OAuth
  client configured) and (b) Urge Lock's screen-pinning has no iOS
  equivalent and falls back to explaining Guided Access. This native
  rewrite follows the same two decisions for the same reasons.

## 2. Features discovered

- **Urge Mode** — the core "I HAVE AN URGE" flow: a signature
  wave→circle animation, an optional "remember why" + intensity (1–10)
  step, then either a distraction loop (intensity < 7) or **Urge
  Lock** (intensity 7–10, a 5/8/12/15-minute timed session).
- **Activities tab** — 9 curated exercises across Distract / Challenge
  / Calm, browsable any time, plus a "seems to help you" recommendation
  based on session history.
- **Progress tab** — a "Resistance Level" score (points from app-open
  days + streak + urge-session outcomes), most-used/most-helpful
  lists.
- **Journal** — private, on-device-only free-write or prompted entries.
- **Settings** — Account, Appearance, Notifications & Reminders (daily
  nudge + custom per-time reminders), Urge Lock setup, My Reasons,
  Reach Out (one-tap SMS to a saved contact), What You're Protecting,
  Privacy & Your Data (export/clear), Get Support (non-clinical
  resources), About.
- **Account** — optional Firebase email/password auth; sign-in is
  never required for any core feature.
- **Dashboard** — profile picture (kept on-device), editable name,
  Resistance Level summary, capped notification history.
- **Onboarding** — welcome + 4 tutorial slides + "choose your
  activities" + a "you're in control" disclaimer screen, shown once.

## 3. iOS implementation — feature-by-feature

| Android/web original | iOS native equivalent |
|---|---|
| DOM screen router (`app.js`) | `AppRouter` (`ObservableObject`) + `NavigationStack` / `.sheet` / `.fullScreenCover` |
| `localStorage` / Capacitor `Preferences` (`storage.js`) | `UserDefaults` via `DataStore` (`Models/DataStore.swift`) — same key-per-concept shape, same public method names |
| `screens.js` (5 tabs) | `HomeView`, `ActivitiesTabView`, `ProgressTabView`, `JournalTabView`, `SettingsTabView` |
| `flows.js` (splash / login gate / Urge Mode / onboarding) | `SplashView`, `LoginGateView`, `UrgeModeView`, `OnboardingView` |
| `activities.js` (9 games) | 9 SwiftUI runner views under `Views/Activities/Runners/`, dispatched by `ActivityRunnerDispatch` |
| `distractions.js` (~30 generators) | `DistractionEngine.swift` — the full weighted-random-with-no-repeat picker architecture, plus **8 representative generator types** (HALT check, Urge Surfing, Wait It Out, Quick Math, Tap When Green, Don't Tap, Fastest Finger, Odd One Out) spanning every interaction pattern the original ~30 use. **Not all ~30 web generators were ported** — see "Known gaps" below. |
| Firebase Auth (email + Google, Android) | Firebase Auth iOS SDK, **email/password only** — Google Sign-In is intentionally left out on iOS, exactly as `account.js`'s own comment documents for why it's Android-only (no iOS OAuth client configured) |
| Android Screen Pinning (Urge Lock) | **No iOS equivalent exists.** `UrgeLockConfirmView`/`UrgeLockSubview` explain this plainly and point to Apple's Guided Access (Settings → Accessibility → Guided Access, user-triggered by triple-click) instead of implying an in-app control that can't exist |
| Android notifications (local + FCM) | `NotificationsService.swift` using `UNUserNotificationCenter` — daily nudge + custom per-time reminders, all local; no server component |
| SharedPreferences | `UserDefaults` |
| Firebase Cloud Messaging (push) | Not implemented — see "Known gaps" |
| Profile picture upload | `PhotosUI` `PhotosPicker`, kept in memory / could be persisted to disk — never uploaded |
| Google-Places/contacts style "Reach Out" | `sms:` URL scheme via `UIApplication.open` |

## 4. Files created

```
ios/
  project.yml                        XcodeGen spec (generates the .xcodeproj in CI — see below)
  UrgeAway/
    UrgeAwayApp.swift                App entry point, Firebase bootstrap, launch-stage routing
    Models/
      Models.swift                  AppSession, JournalEntry, Reminder, Settings, ResistanceStats, etc.
      DataStore.swift               UserDefaults-backed store — 1:1 port of storage.js
      ActivityDefinition.swift      The 9-activity registry
    Services/
      AppRouter.swift                Navigation state
      AuthService.swift              Firebase Auth wrapper (email/password only)
      NotificationsService.swift     UNUserNotificationCenter wrapper
    Views/
      Home/HomeView.swift
      UrgeMode/UrgeModeView.swift, UrgeLockView.swift, DistractionEngine.swift
      Activities/ActivitiesTabView.swift, ActivityRunnerScreen.swift, RunnerComponents.swift,
                 Runners/ (6 files, 9 activity runners)
      Progress/ProgressTabView.swift
      Journal/JournalTabView.swift
      Settings/SettingsTabView.swift + 5 subview files
      Account/AccountView.swift
      Dashboard/DashboardView.swift
      Onboarding/SplashView.swift, OnboardingView.swift
      Components/Theme.swift         Design tokens ported from styles.css
      RootTabView.swift
    Resources/
      Info.plist
      Assets.xcassets/               AppIcon + AccentColor placeholders
  UrgeAwayTests/
    UrgeAwayTests.swift              Model/DataStore unit tests
.github/workflows/ios-native.yml     CI build/test workflow (separate from the original build-ios.yml)
original-capacitor-app/              The uploaded project, unchanged
```

32 Swift files, ~3,600 lines.

## 5. Dependencies

- **Firebase iOS SDK** (`FirebaseAuth`, `FirebaseCore`) via Swift
  Package Manager, resolved from `project.yml`. No CocoaPods.
- **PhotosUI** (system framework) for the profile-picture picker.
- No other third-party dependencies.

## 6. Features requiring manual configuration

These cannot be filled in automatically and are not faked:

- **`GoogleService-Info.plist`** — not included (no real Firebase iOS
  app was created for this migration). Drop it into
  `ios/UrgeAway/Resources/` and add it to the Xcode target. Until
  it's added, `AuthService.isAvailable` is `false` and Account shows a
  plain notice — every other feature works normally.
- **Apple Developer Team / Bundle ID** — `project.yml` uses
  `com.example.urgeaway` and an empty `DEVELOPMENT_TEAM`. Change both
  before any real-device or TestFlight build.
- **Signing certificates / provisioning profiles** — none exist for
  this repo. CI builds unsigned, for iOS Simulator only.
- **APNs / push notifications** — not implemented at all (see "Known
  gaps"). The original's `push.js`/FCM broadcast-message feature has
  no iOS counterpart here yet.
- **App Store Connect** — nothing here touches it.

## 7. GitHub Actions — what `ios-native.yml` does

1. Checks out the repo, selects an Xcode 16.2 runner (`macos-15`).
2. Installs **XcodeGen** and runs `xcodegen generate` inside `ios/` —
   this produces `UrgeAway.xcodeproj` from `project.yml` at build
   time. (No hand-authored `.pbxproj` is committed — generating it
   deterministically in CI is more reliable than a hand-written one
   that was never opened in real Xcode.)
3. Resolves Swift Package dependencies (Firebase).
4. Builds the `UrgeAway` scheme for an iOS Simulator destination,
   with `CODE_SIGNING_ALLOWED=NO` / `CODE_SIGNING_REQUIRED=NO` — no
   secrets needed.
5. Runs the unit test target the same way.
6. Locates the built `.app` in DerivedData, zips it, and uploads it as
   a workflow artifact (`UrgeAway-iOS-Simulator-build`).
7. Does **not** attempt to produce a signed IPA — that needs a real
   Apple Developer Team and certificate, which don't exist here (see
   above).

## 8. Build instructions (local, in Xcode)

```bash
cd ios
brew install xcodegen   # once
xcodegen generate
open UrgeAway.xcodeproj
```
Then pick an iOS Simulator and hit Run. To use a real device, set your
own Team ID and bundle identifier in `project.yml` (or in Xcode's
Signing & Capabilities tab) first.

## 9. GitHub Actions instructions

Push to `main` (or open a PR) touching anything under `ios/`, or run
the workflow manually from the Actions tab
("iOS (native Swift) build" → *Run workflow*). When it finishes,
download `UrgeAway-iOS-Simulator-build` from the run's Artifacts
section, unzip it, and drag `UrgeAway.app` onto a running Simulator
(or `xcrun simctl install booted UrgeAway.app`).

## 10. Verifying the build

**This has not been compiled.** No macOS/Xcode environment was
available to produce this code, so treat it as a first draft that
needs its first real CI run (or a local Xcode open) before you trust
it. Likely first-run friction, in rough order of likelihood:

- Minor SwiftUI API mismatches (e.g. `gridCellColumns` usage, iOS 17
  APIs) that a real compiler will catch immediately and are typically
  one-line fixes.
- `project.yml`'s Xcode/iOS version pins may need adjusting to match
  whatever the `macos-15` runner actually has installed by the time
  you run this.

## 11. Known gaps — full list, not omitted

- **Distraction generator breadth:** `distractions.js` has ~30
  generator *types* built from large content banks (memory-replay
  prompts, "build your dream" builders, logic puzzles, grid memory,
  color sequences, etc.). This port implements the full picker
  architecture plus **8 generator types** covering every interaction
  *pattern* used across all ~30 (guided prompt sequences, HALT-style
  branching check-ins, reaction/attention games, forced-choice
  puzzles). The remaining ~22 are content variations of these same
  patterns, not new mechanics — each can be added as one more `case`
  in `DistractionKind` plus one more SwiftUI view, following
  `DistractionEngine.swift`'s existing structure.
- **Push notifications (FCM broadcast messages):** `push.js` is not
  ported. Local notifications (daily nudge + custom reminders) are
  fully implemented via `UNUserNotificationCenter`.
- **Profile picture persistence:** currently held in view state for
  the session; the original compresses to a square JPEG data URL and
  persists it. Wiring `PhotosPicker` output to disk storage (and
  loading it back in `DataStore`) is a small follow-up.
- **Google Sign-In:** intentionally absent on iOS, matching the
  original's own documented Android-only decision.
- **Screen-pinning-equivalent:** intentionally absent — no iOS API
  exists for an app to lock itself to the screen. Guided Access is
  explained instead of faked.
