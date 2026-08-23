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

## 4. Phase 2 — Spotify (needs a real iPhone + Premium)
- [ ] Create an app in the Spotify Developer Dashboard.
- [ ] Set bundle id `nu.ronnqvist.rinkdj` + redirect URI (e.g. `rinkdj://spotify-callback`).
- [ ] Ask Claude to implement `SpotifyEngine` (currently a stub) with the Spotify iOS SDK.
- [ ] Test on a physical iPhone with the Spotify app installed (won't work in the Simulator).

---
Notes: Apple ID only needed to run on a real phone (Simulator needs none). Keep ~40 GB free.
Full details in `README.md`.
