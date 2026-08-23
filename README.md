# RinkDJ 🏒🎵

A game-day music controller for hockey officials. During a match the music operator
normally juggles the Spotify app — stepping through a playlist, jumping to a goal
song, pausing, skipping — all while play moves fast. **RinkDJ** replaces that with a
screen of big, one-tap buttons, each bound to the right audio action.

Default team branding is **Flemingsbergs IK**, but any club can set its own name,
logo and colour — the app is not locked to one team.

---

## Status: Phase 1 (local audio, runs in the Simulator)

- ✅ **Phase 1 — done:** full app with Control + Setup screens, playing **local MP3/WAV
  files**. Runs entirely on the iOS Simulator, no accounts required.
- ⏳ **Phase 2 — later:** Spotify playback via the Spotify iOS SDK. Requires a **physical
  iPhone** with the Spotify app + a **Premium** account (the SDK can't run in the Simulator).
  You can already enter Spotify URIs in Setup today; they're saved and used once Phase 2 lands.

---

## Prerequisites

1. **Install Xcode** from the Mac App Store (large download; required for any iOS build —
   the Command Line Tools alone are not enough).
2. After installing, point the toolchain at it once:
   ```
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

## Build & run (Simulator)

1. Open the project:
   ```
   open RinkDJ.xcodeproj
   ```
2. In Xcode's toolbar, pick an iPhone Simulator (e.g. *iPhone 16*).
3. Press **▶ Run** (⌘R).

The app launches with demo sounds already configured, so every button makes a sound
immediately.

## Using the app

**Match tab (Control):**

| Button | What it does |
|---|---|
| **Avblåsning** (whistle) | Advance to the **next track** in the game playlist and play it |
| **Tekning** (face-off) | **Stop** all audio (play has resumed) |
| **Hemmamål / Bortamål** | Play the configured home / away goal track |
| **Hemmautvisning / Bortautvisning** | Play the configured home / away penalty track |
| **Timeout** | Play the configured timeout track |
| **Paus** (intermission) | Play the intermission playlist (loops) |
| **Matchslut** (game end) | Play the configured end track (e.g. club anthem) |

The bar at the bottom shows what's playing and has a **stop** button.

**Inställningar tab (Setup):**
- **Lag** — team name, accent colour, and logo (import your own).
- **Spellista / Paus-spellista** — import MP3s, reorder, delete. Whistle steps through
  the game playlist; Paus plays the intermission playlist.
- **Händelselåtar** — bind one track to each of Hemmamål, Bortamål, Hemmautvisning,
  Bortautvisning, Timeout and Matchslut (local MP3 today, Spotify URI in Phase 2).
- **Återställ till demo** — restore the bundled demo configuration.

Config is saved as JSON in the app's Documents directory and survives relaunch.

## Adding the Flemingsbergs IK logo

The app ships with a neutral placeholder. To bundle the real logo:
1. Get a transparent **PNG** (~1024×1024).
2. In Xcode, open `Assets.xcassets` → **TeamLogo**, and drag the PNG onto the image well
   (or drop three sizes into the `1x/2x/3x` slots).

Any other club can instead import their own logo at runtime via **Setup → Lag → Importera
logotyp**.

## Phase 2 — enabling Spotify (later, real device)

1. Create an app in the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard).
2. Set the bundle id `nu.ronnqvist.rinkdj` and a redirect URI (e.g. `rinkdj://spotify-callback`).
3. Add the Spotify iOS SDK (Swift Package or xcframework), a URL scheme, and
   `LSApplicationQueriesSchemes` for `spotify`.
4. Implement `SpotifyEngine` (currently a stub) using `SPTSessionManager` + `SPTAppRemote`.
5. Run on a **physical iPhone** with the Spotify app installed and a **Premium** account.

---

## Project layout & notes for a backend developer

```
RinkDJ/
  RinkDJApp.swift        @main entry; injects shared services into the SwiftUI environment
  Models/                Plain value types (Codable) — like your DTOs/entities
  Store/                 ConfigStore (persistence), FileStore (paths), PlaybackCoordinator (business logic)
  Audio/                 AudioEngine protocol + Local (AVAudioPlayer) and Spotify (stub) implementations
  Views/                 SwiftUI screens (declarative UI)
  Resources/Sounds/      Bundled demo WAV tones
  Assets.xcassets/       App icon, accent colour, team logo
```

A few Swift↔Java signposts:
- **`enum AudioResource`** with associated values = a sealed sum type (Java `sealed`/records).
- **`protocol AudioEngine`** + `LocalAudioEngine`/`SpotifyEngine` = interface + implementations,
  selected at runtime (Strategy pattern) by `PlaybackCoordinator`.
- **`@Observable` `ConfigStore` / `PlaybackCoordinator`** = observable singleton services the
  UI binds to (think injected beans).
- **`Codable`** = built-in JSON (de)serialisation, like Jackson but compiler-generated.

The `.xcodeproj` uses Xcode 16 **file-system synchronized groups**: any file you add under
`RinkDJ/` is picked up automatically — no manual project bookkeeping.
