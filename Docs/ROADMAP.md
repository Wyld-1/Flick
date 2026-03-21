# Flick - Roadmap

**Vision:** A production-ready gesture-based music controller with ML-powered gesture recognition, available to the public via TestFlight or App Store.

---

## Phase 1: Core Product (COMPLETE ✅)

**Goal:** Functional gesture detection + media control for personal use

- [x] Basic gesture detection (flick left/right, upside-down hold)
- [x] Apple Music integration via MPMusicPlayerController
- [x] WatchConnectivity messaging (Watch → iPhone)
- [x] Background execution via HealthKit workout session
- [x] Settings persistence via App Groups
- [x] Onboarding flow (permissions, tutorial)
- [x] Haptic feedback on gestures

**Status:** Complete as of January 2026

---

## Phase 2: Multi-Platform Support (COMPLETE ✅)

**Goal:** Work with popular music services beyond Apple Music

- [x] Spotify integration via SPTAppRemote SDK
- [x] OAuth flow for Spotify authorization
- [x] Token persistence and auto-reconnection
- [x] iOS Shortcuts integration (URL scheme)
- [x] Playback method selector in onboarding
- [x] Settings sync between Watch and iPhone

**Status:** Complete as of February 2026

---

## Phase 3: ML Data Infrastructure (COMPLETE ✅)

**Goal:** Build pipeline for collecting training data from users

- [x] DataCollectionManager (Watch): 50Hz sensor recording
- [x] DataCollectionCoordinator (iPhone): Gesture labeling UI
- [x] State synchronization via SharedSettings
- [x] WatchConnectivity file transfer for sensor data
- [x] CSV generation (timestamped sensor data + labels)
- [x] iOS share sheet export for data collection
- [x] Real-time progress indicators (sample count, duration, transfer %)

**Status:** Complete as of March 14, 2026

---

## Phase 4: ML Model Training (IN PROGRESS 🔄)

**Goal:** Replace hardcoded thresholds with trained CoreML model

### 4.1 Data Collection
- [x] Infrastructure in place (share sheet export)
- [ ] **NEXT:** Recruit 5-10 beta testers
- [ ] Collect 50-100 labeled gesture sessions
- [ ] Diversity: Different wrist sizes, movement styles, handedness
- [ ] Quality check: Verify CSV labels match actual gestures

### 4.2 Model Training
- [ ] Export data to Python/Jupyter environment
- [ ] Exploratory data analysis (sensor distributions, gesture patterns)
- [ ] Feature engineering (if needed beyond raw sensor data)
- [ ] Train classification model (Random Forest, LSTM, or Create ML)
- [ ] Evaluate on held-out test set (accuracy, precision, recall per gesture)
- [ ] Export to CoreML format (.mlmodel file)

### 4.3 Model Integration
- [ ] Add .mlmodel to Xcode project
- [ ] Create MLModelWrapper class for inference
- [ ] Replace MotionManager threshold logic with model predictions
- [ ] A/B test: Hardcoded vs ML (accuracy comparison)
- [ ] Tune confidence thresholds to minimize false positives

**Blockers:** Need volume of training data (Phase 4.1)

**Target Completion:** April 2026 (depends on tester recruitment)

---

## Phase 5: Automatic Data Upload (DEFERRED 🔄)

**Goal:** Scale data collection from 10 testers to 50+ without manual file sharing

### 5.1 Firebase Integration (ON HOLD)
- [x] Firebase project created
- [x] Security rules configured (write-only access)
- [x] Swift code written (FirebaseUploader, quota management)
- [x] Documentation complete (3 .md files)
- [ ] **DECISION NEEDED:** Firebase vs share sheet for current scale

**Current State:**
- `firebase-integration` git branch exists with complete implementation
- Main branch reverted to share sheet (March 14 commit)
- Share sheet sufficient for 10-20 testers
- Revisit when scaling to 50+ testers or public TestFlight

**Alternative Considered:**
- Google Drive service account (failed due to secret scanner)
- Custom backend (overkill for current needs)

**Next Steps (if/when activated):**
1. Merge `firebase-integration` branch
2. Test on real hardware
3. Set up Firebase quota monitoring
4. Deploy Cloud Function for email alerts (80%/90% storage)

---

## Phase 6: Polish & Optimization (NOT STARTED 📋)

**Goal:** Production-ready stability and UX

### 6.1 Gesture Tuning
- [ ] ML model deployed and tested in real-world use
- [ ] User feedback loop: Collect false positive/negative reports
- [ ] Iterate on confidence thresholds
- [ ] Add gesture history visualization for debugging
- [ ] Measure gesture → playback latency (target < 200ms)

### 6.2 Code Quality
- [ ] Replace debug print statements with os_log
- [ ] Extract large views into subcomponents (DataCollectionView, etc.)
- [ ] Move magic numbers to configuration file or UserDefaults
- [ ] Add unit tests for SharedTypes, WatchConnectivityManager
- [ ] SwiftLint integration for code style consistency

### 6.3 Error Handling
- [ ] Graceful degradation when Spotify/Apple Music unavailable
- [ ] User-facing error messages (not just console logs)
- [ ] Retry logic for all network operations
- [ ] Offline mode indicator
- [ ] Background task completion handlers

### 6.4 Accessibility
- [ ] VoiceOver support for all screens
- [ ] Dynamic Type support (larger text sizes)
- [ ] Haptic feedback customization (intensity settings)
- [ ] Color contrast review (WCAG compliance)

---

## Phase 7: Public Beta (NOT STARTED 📋)

**Goal:** TestFlight distribution to external testers

### 7.1 App Store Preparation
- [ ] App Store Connect account setup
- [ ] Bundle identifier registration
- [ ] Privacy policy written and hosted
- [ ] App Store screenshots (iPhone and Watch)
- [ ] App description and keywords
- [ ] Beta testing agreement (terms of use)

### 7.2 TestFlight Launch
- [ ] Internal testing (friends & family)
- [ ] Fix critical bugs from internal testing
- [ ] External beta release (100-1000 testers)
- [ ] Crash reporting integration (Sentry or Firebase Crashlytics)
- [ ] User feedback collection (in-app survey or email)
- [ ] Iterate based on feedback

### 7.3 Metrics & Analytics
- [ ] Define success metrics (DAU, gesture accuracy, retention)
- [ ] Privacy-preserving analytics (no PII)
- [ ] Crash rate monitoring
- [ ] Gesture detection success rate tracking
- [ ] Battery impact measurement

**Target Completion:** June 2026 (aspirational)

---

## Phase 8: App Store Release (NOT STARTED 📋)

**Goal:** Public 1.0 release on App Store

### 8.1 Final Polish
- [ ] All TestFlight bugs fixed
- [ ] Performance optimizations (battery, latency)
- [ ] Final QA pass on all device types
- [ ] App Store review guidelines compliance check
- [ ] Privacy nutrition label completion

### 8.2 Launch Preparation
- [ ] App Store submission (first round)
- [ ] Address Apple review feedback (expect 1-2 rejections)
- [ ] Finalize pricing model (free vs paid vs IAP)
- [ ] Marketing plan (if any): Reddit posts, Product Hunt, etc.
- [ ] Support email setup (for user questions)

### 8.3 Post-Launch
- [ ] Monitor crash reports and reviews
- [ ] Rapid hotfix cycle for critical bugs
- [ ] First update planning (based on user feedback)
- [ ] Long-term roadmap review

**Target Completion:** August 2026 (aspirational)

---

## Future Considerations (BACKLOG 💭)

**Not committed to, but worth exploring:**

### Additional Gestures
- Tap detection (double-tap for play/pause?)
- Shake gesture (shuffle playlist?)
- Rotation hold (volume control?)
- Risk: Too many gestures → accidental triggers

### Platform Expansion
- CarPlay integration (CPNowPlayingTemplate)
  - Requires Apple entitlement (unknown feasibility)
- Mac companion app (control iTunes/Music.app)
- Android Wear port (different sensor APIs)

### Advanced Features
- Customizable gesture → action mapping (user choice)
  - Conflicts with "fixed for consistency" philosophy
- Gesture macros (e.g., "flick left twice" = skip 30s)
- Context-aware detection (pause gestures during workouts?)
- Multi-device support (control multiple iPhones)

### Business Model
- Free with ads (conflicts with "no screen time" philosophy)
- Freemium (basic gestures free, advanced paid)
- One-time purchase ($2.99-$4.99)
- Subscription (probably not justified for this product)

---

## Decision Log

**Why share sheet over Firebase for now?**
- 10-20 testers = manageable manually
- Firebase adds complexity (quota monitoring, email alerts)
- Faster iteration on ML model without backend dependency
- Can always add auto-upload later if scaling to 50+ testers

**Why not customize gestures?**
- Core philosophy: Fixed gestures = muscle memory
- Every customization option = higher cognitive load
- Three gestures is minimal viable set
- May reconsider based on user feedback

**Why ML model over tuned thresholds?**
- Thresholds assume all users move identically (false)
- Model can learn individual patterns (better accuracy)
- Data collection infrastructure already built
- Long-term investment in product quality

---

## Review Cadence

**This roadmap should be reviewed:**
- After each phase completion
- Monthly during active development
- When user feedback indicates priority shifts
- Before any major pivot or architectural decision

**Last Reviewed:** March 20, 2026  
**Next Review:** April 1, 2026 (or when Phase 4.1 completes)
