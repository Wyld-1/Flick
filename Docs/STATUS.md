# Flick - Current Status

**Last Updated:** March 20, 2026  
**Build Target:** iOS 26+ / watchOS 26+  
**Xcode Version:** 26.0+

---

## ✅ Fully Working

### Core Functionality
- **Gesture detection on Apple Watch**
  - Flick left/right detection (rotation threshold: 1.8 rad/s)
  - Upside-down hold detection (gravity threshold: 0.6, hold time: 1.2s)
  - Background execution via HealthKit workout session
  - Haptic feedback on gesture recognition
  
- **Media playback control**
  - Apple Music via MPMusicPlayerController (built-in, no setup)
  - Spotify via SPTAppRemote SDK 5.0.1 (OAuth working, token persistence)
  - iOS Shortcuts integration via URL scheme
  - Command queuing and retry mechanism for offline scenarios

- **WatchConnectivity communication**
  - Bidirectional settings sync via App Groups
  - MediaCommand messaging (Watch → iPhone)
  - File transfer for ML training data
  - Reachability monitoring and auto-retry

- **Onboarding flow**
  - Welcome screen with HealthKit permission request
  - Playback method selection (Apple Music/Spotify/Shortcuts)
  - Spotify OAuth flow via Safari redirect
  - Tutorial completion blocker (Continue on Watch screen)
  - State persistence across app restarts

- **ML data collection pipeline**
  - Watch: 50Hz sensor data recording (rotation, gravity, acceleration)
  - iPhone: Gesture labeling via button press UI
  - File transfer: Watch → iPhone via WCSession
  - CSV generation: Timestamped sensor data + labels
  - iOS share sheet export (Files, AirDrop, email, etc.)

### UI/UX
- **iPhone app**
  - State-based navigation (Welcome → Setup → Waiting → Main)
  - Main view with connection status, recent gesture display
  - Data collection interface with real-time sample count
  - Settings management=
  
- **Watch app**
  - ContentView with gesture icons and last detected gesture
  - Interactive tutorial (swipe through gesture demonstrations)
  - Data collection view with duration counter
  - Settings view for simple settings and tutorial restart

---

## ⚠️ Partially Working / Known Issues

### Gesture Detection Accuracy
- **Status:** Functional but not tuned
- **Issue:** Hardcoded thresholds don't account for individual movement patterns
- **Impact:** Some users may find gestures over-sensitive or under-sensitive
- **Workaround:** Thresholds are adjustable in code (MotionManager.swift)
- **Long-term fix:** Train ML model on collected data, replace hardcoded logic

### WatchConnectivity File Transfer in Simulator
- **Status:** Unreliable in iOS Simulator
- **Issue:** `didReceive(file:)` delegate method often never fires
- **Impact:** ML data collection appears to hang at "Transferring data: 100%"
- **Workaround:** Test on real hardware only
- **Apple Bug:** Known limitation of WatchConnectivity simulator support

### Spotify Connection Persistence
- **Status:** Works but requires occasional reconnection
- **Issue:** SPTAppRemote disconnects after ~30 minutes of inactivity
- **Impact:** First gesture after disconnect may fail, second succeeds
- **Workaround:** Auto-reconnect logic triggers on first command failure
- **Behavior:** User sees no error, just slight delay (< 1s) on first use

---

## ❌ Not Implemented / Blocked

### Custom ML Model
- **Status:** Infrastructure in place, model not trained
- **Reason:** Waiting to collect sufficient training data from testers
- **Blockers:** None technical, just need volume of labeled data
- **Next Steps:** 
  1. Collect 50-100 sessions from 5-10 testers
  2. Train CoreML model in Create ML or Python
  3. Replace MotionManager thresholds with model inference

### Automatic Data Upload
- **Status:** Deferred to future iteration
- **Previous Attempt:** Google Drive service account (failed due to secret scanning)
- **Current State:** Manual share sheet export only
- **Considered Solutions:**
  - Firebase Storage with anonymous auth (documentation written, not implemented)
  - Custom backend server (overkill for current scale)
- **Decision:** Share sheet sufficient for 10-20 testers, revisit at 50+ users

### Gesture Customization
- **Status:** Intentionally not planned
- **Reason:** Fixed gesture → action mapping is core to the product philosophy
- **User Requests:** None yet, may reconsider based on feedback

---

## 🐛 Bug Log

### BUG-001: WatchConnectivity File Transfer Never Completes (Simulator)
- **Reported:** March 14, 2026
- **Severity:** Low (simulator-only)
- **Reproducible:** Always in iOS Simulator, never on real hardware
- **Root Cause:** Apple's WatchConnectivity simulator doesn't fully implement file transfer
- **Logs:**
  ```
  ⌚️ File transfer initiated - isTransferring: true
  ⌚️ Transfer progress: 100%
  [iPhone didReceive(file:) never called]
  ```
- **Attempted Fixes:**
  - Verified WCSession activation state (correct)
  - Added progress KVO observer (progress shows 100%, but delegate never fires)
  - Tested with minimal JSON payloads (same result)
- **Workaround:** Test data collection on real hardware
- **Status:** Won't fix (Apple limitation)

### BUG-002: Share Sheet Doesn't Appear in Simulator
- **Reported:** March 14, 2026
- **Severity:** Low (simulator-only, cosmetic)
- **Reproducible:** Intermittent
- **Root Cause:** UIActivityViewController sometimes fails to present in simulator
- **Workaround:** CSV file still saved to temp directory, accessible via Finder
- **Status:** Accepted (simulator limitation)

---

## 🔧 Technical Debt

### Code Organization
- **Issue:** Some view files are 300+ lines (e.g., DataCollectionView)
- **Impact:** Moderate - harder to maintain
- **Priority:** Low
- **Refactor Plan:** Extract subviews when adding new features

### Telemetry Logging
- **Issue:** Debug print statements throughout codebase (e.g., `📱 [TELEMETRY]`)
- **Impact:** Low - useful for debugging, but verbose
- **Priority:** Low
- **Plan:** Replace with proper logging framework (os_log) before public release

### Hardcoded Constants
- **Issue:** Magic numbers in MotionManager (thresholds, cooldowns)
- **Impact:** Moderate - difficult to tune without code changes
- **Priority:** Medium
- **Plan:** Move to configuration file or UserDefaults

---

## 📱 Platform-Specific Notes

### watchOS
- **Minimum version:** watchOS 10.0
- **Tested on:** Apple Watch Series 9, SE (2nd gen)
- **Simulator support:** Limited (no CoreMotion, no HealthKit)
- **Background execution:** Requires workout session (works reliably)

### iOS
- **Minimum version:** iOS 17.0
- **Tested on:** iPhone 15 Pro, 14, SE (3rd gen)
- **Simulator support:** Full (except WatchConnectivity file transfer)
- **External dependencies:** Spotify iOS SDK 5.0.1 (binary framework)

---

## 🚀 Deployment Status

### Development
- **Current Branch:** `main` (share sheet version)
- **Alternative Branch:** `firebase-integration` (auto-upload, not active)
- **Last Stable Commit:** `bc84034` (March 14, 2026)

### Testing
- **Internal Testing:** Active (developer + 2-3 friends)
- **TestFlight:** Not deployed
- **App Store:** Not submitted

### Build Configuration
- **Bundle ID (iOS):** `wildcat.gestureplayback.Flick`
- **Bundle ID (watchOS):** `wildcat.gestureplayback.Flick.watchkitapp`
- **App Group:** `group.flickplayback.SharedFiles`
- **URL Scheme:** `flick://callback` (for Spotify OAuth)

---

## 📋 Next Session Checklist

**If working on gesture detection:**
1. Load MotionManager.swift
2. Current thresholds are in private constants at top of class
3. Test changes on real Watch hardware (simulator has no sensors)

**If working on data collection:**
1. Verify `firebase-integration` branch status if considering auto-upload
2. Current version uses share sheet (works, but manual)
3. WatchConnectivity file transfer only works on real hardware

**If working on Spotify:**
1. Token stored in UserDefaults as "spotifyAccessToken"
2. Reconnection logic in iOSMediaManager.connectToSpotify()
3. Check SPTAppRemote.isConnected before assuming connection

**If adding new gestures:**
1. Update MotionManager.detectX() methods
2. Add new MediaCommand case to SharedTypes
3. Update iOSMediaManager.handleCommand() switch statement
4. Update tutorial UI on both platforms

---

## 🎯 "Definition of Done" Checklist

For a feature to be considered complete:
- [ ] Works on real hardware (both iPhone and Watch)
- [ ] Handles offline/disconnected scenarios gracefully
- [ ] State persists across app restarts (if stateful)
- [ ] Error states provide user feedback (haptic + visual)
- [ ] Code includes telemetry logging for debugging
- [ ] Tested with all three playback methods (if relevant)
- [ ] No force-unwraps or unhandled optionals
- [ ] No warnings in Xcode build output
