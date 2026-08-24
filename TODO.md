# RinkDJ — TODO (your next steps)

Status: **Phase 1 is built and ready.** These are the things *you* need to do.

## 1. Install Xcode (blocks everything)
- [ ] Open the App Store → search **Xcode** → Get (it's ~7–15 GB, so leave it running).
      Shortcut: `open "macappstore://apps.apple.com/app/id497799835"`
- [ ] Launch Xcode once; let it **install additional components** and accept the license.
- [ ] Point the toolchain at Xcode:
      `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- [ ] Verify: `xcodebuild -version && xcrun simctl list runtimes | grep iOS`

## 2. Run the app (Simulator)
- [ ] `open /Users/peterronnqvist/source/hockey/RinkDJ.xcodeproj`
- [ ] Pick an iPhone simulator in the toolbar, press ▶ (⌘R).
- [ ] Smoke test:
  - [ ] **Avblåsning** → steps through demo tracks
  - [ ] **Tekning** → stops audio
  - [ ] **Hemmamål / Timeout / Matchslut** → plays the demo one-shots
  - [ ] **Inställningar** → import an MP3, reorder a playlist, confirm it persists after relaunch
- [ ] Paste any Xcode build errors to Claude to fix.

## 3. Polish (optional, when you have time)
- [ ] Replace demo WAV tones with real goal horn / music files.
- [ ] Confirm Swedish wording on buttons reads well for officials.
- [ ] Tweak app-icon padding / accent colour if desired.

## 4. Phase 2 — Spotify (needs a real iPad/iPhone + Premium)
- [x] Create an app in the Spotify Developer Dashboard (RinkDJ).
- [x] Redirect URI registered: `nu.ronnqvist.rinkdj://spotify-login-callback`.
- [x] Spotify iOS SDK added via Swift Package Manager (`github.com/spotify/ios-sdk`).
- [x] `SpotifyEngine` implemented with `SPTAppRemote` (App Remote flow, no backend/secret).
- [x] Info.plist wired: URL scheme `nu.ronnqvist.rinkdj` + `LSApplicationQueriesSchemes` = spotify.
- [x] Builds green for the Simulator (Spotify features are inert there by design).
- [x] **Rotated the Spotify client secret** in the dashboard (2026-08-24). The app does
      NOT use it anyway — App Remote flow uses only the Client ID + redirect URI.
- [ ] Deploy to a **physical iPad/iPhone** from Xcode (set your Signing team).
- [ ] With the **Spotify app installed + logged into Premium**, open the Spotify tab →
      **Anslut Spotify** → approve → then test Spotify-bound events on the Match screen.

---
Notes: Apple ID only needed to run on a real phone (Simulator needs none). Keep ~40 GB free.
Full details in `README.md`.
