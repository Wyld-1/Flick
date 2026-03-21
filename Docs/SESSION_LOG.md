# Flick - Session Log

**Purpose:** Running log of development sessions, key decisions, and context that won't be obvious from code alone.

---

## 2026-03-20 | Thursday | Documentation System Created

**Session Type:** Codebase audit + documentation generation

**Context for Future Sessions:**
Lion (developer) requested comprehensive documentation system to onboard new developers or resume work after breaks. This is the first session using this log format.

**Work Completed:**
- Full codebase read: All Swift files, build configs, project structure
- Created 5 documentation files in `Docs/` folder:
  - `OVERVIEW.md` - Product vision, gesture philosophy, why Flick exists
  - `ARCHITECTURE.md` - System design, data flows, file structure, communication patterns
  - `STATUS.md` - Current build state, working/broken features, bug log
  - `ROADMAP.md` - Feature roadmap in phases with completion status
  - `SESSION_LOG.md` (this file)
- Updated `README.md` to be GitHub-ready public face of project

**Key Findings from Codebase:**
- Current version: March 14, 2026 commit (`bc84034`) with share sheet export
- Alternative branch exists: `firebase-integration` (auto-upload, not active)
- ML pipeline fully built but no model trained yet (waiting for data)
- Gesture detection uses hardcoded thresholds (to be replaced by ML)
- WatchConnectivity file transfer broken in simulator (Apple limitation)
- Spotify integration working with OAuth + token persistence
- Three playback methods supported: Apple Music, Spotify, iOS Shortcuts

**Technical Decisions Made:**
- Documentation structure: Separate concerns (overview/architecture/status/roadmap/log)
- README positioned as public-facing, Docs/ as developer-facing
- STATUS.md is the "open this first" file for any new session
- ROADMAP.md tracks completion status, not just future plans

**Deferred Items:**
- Bundle IDs not verified (noted in STATUS.md to check in Xcode)
- Some implementation details inferred from code (marked in docs)
- Firebase auto-upload decision deferred (on separate branch)

---

## 2026-03-15 to 2026-03-19 | Firebase Integration Work (Not in Main Branch)

**Session Type:** Auto-upload experimentation (from transcript review)

**Context:**
Series of sessions attempting to add automatic ML data upload. Originally tried Google Drive service account approach, but Google's secret scanner detected committed credentials and disabled the account. Pivoted to Firebase Storage.

**Work Completed (on `firebase-integration` branch):**
- Firebase project created: "Flick ML Training"
- Security rules configured (write-only, anonymous auth)
- Swift implementation:
  - `FirebaseUploader.swift` - Singleton with quota management
  - `TrainingDataCache.swift` - Local fallback when quota exceeded
  - `PendingUploadsManager.swift` - Auto-retry on app launch
  - Modified `DataCollectionCoordinator.swift` to use Firebase instead of share sheet
- Updated `.gitignore` to block service account credentials (by blocking all .json files)

**Decision Made:**
Reverted main branch to March 14 commit (`bc84034`) with share sheet. Firebase work saved on separate branch for potential future use.

**Reasoning:**
- Share sheet sufficient for 10-20 testers (current scale)
- Firebase adds complexity (quota management, monitoring)
- Faster iteration on ML model without backend dependency
- Can merge `firebase-integration` branch later if scaling to 50+ users

**Git State:**
- `main` branch: Share sheet version (bc84034)
- `firebase-integration` branch: Complete Firebase implementation
- All Firebase files preserved but not in active codebase

---

## 2026-03-14 | ML Data Collection Pipeline Completed

**Session Type:** Feature implementation (from git log + code review)

**Context:**
Completed the full ML training data collection system. This was the culmination of Phase 3 in the roadmap.

**Work Completed:**
- Implemented `DataCollectionManager.swift` (Watch) for 50Hz sensor recording
- Implemented `DataCollectionCoordinator.swift` (iPhone) for gesture labeling
- Added state machine: `.off` → `.recording` → `.syncing` → `.off`
- WatchConnectivity file transfer for motion data (Watch → iPhone)
- CSV generation combining sensor samples with gesture labels
- iOS share sheet for exporting training data
- Real-time UI: sample count, duration timer, transfer progress

**Technical Challenges:**
- WatchConnectivity file transfer doesn't work in simulator
  - Logged as BUG-001 in STATUS.md
  - Workaround: Test on real hardware only
- Initial attempts had state synchronization bugs
  - Fixed by making SharedSettings.dataCollectionState the single source of truth
  - Both platforms observe NotificationCenter "SettingsDidUpdate"

**User Experience:**
1. iPhone: User presses "BEGIN RECORDING", holds gesture buttons
2. Watch: Collects sensor data at 50Hz in background
3. iPhone: User presses "FINISH RECORDING"
4. Watch: Encodes JSON, transfers to iPhone
5. iPhone: Generates CSV, presents share sheet
6. User: Saves to Files/AirDrop/email

**CSV Format Decided:**
```
timestamp,rotX,rotY,rotZ,gravX,gravY,gravZ,userAccelX,userAccelY,userAccelZ,label
```

---

## 2026-02-XX | Spotify + Shortcuts Integration

**Session Type:** Feature implementation (inferred from code)

**Context:**
Extended beyond Apple Music to support other playback methods. This was Phase 2 in the roadmap.

**Work Completed:**
- Integrated Spotify iOS SDK 5.0.1 (binary framework)
- Implemented OAuth flow via Safari redirect (`flick://callback`)
- Token persistence in UserDefaults
- Auto-reconnection logic when SPTAppRemote disconnects
- iOS Shortcuts URL scheme integration
- Playback method selector in onboarding flow
- Settings sync for playback method

**Technical Decisions:**
- Store Spotify token in UserDefaults (not secure keychain)
  - Rationale: No sensitive data, just OAuth token
  - Spotify SDK handles refresh internally
- Three playback methods as enum:
  - `appleMusic`: Built-in, no setup
  - `spotify`: Best UX, requires OAuth
  - `shortcuts`: Escape hatch for other players

**Known Limitations:**
- Spotify disconnects after ~30 min inactivity
- First gesture after disconnect may fail, second succeeds
- Auto-reconnect logic handles this transparently

---

## 2026-01-XX | Core Product (Phase 1)

**Session Type:** Initial development (inferred from code)

**Context:**
Built the foundational gesture detection + media control system.

**Work Completed:**
- MotionManager with CoreMotion sensor reading
- Hardcoded gesture detection thresholds:
  - `TWIST_THRESHOLD = 1.8 rad/s`
  - `UPSIDE_DOWN_THRESHOLD = 0.6`
  - `UPSIDE_DOWN_HOLD_TIME = 1.2s`
  - `GESTURE_COOLDOWN = 0.6s`
- HealthKit workout session for background execution
- WatchConnectivity messaging (Watch → iPhone)
- Apple Music control via MPMusicPlayerController
- SharedTypes.swift for cross-platform type definitions
- Onboarding flow: Welcome → Setup → Tutorial → Main
- Haptic feedback on all gestures

**Design Philosophy:**
- Fixed gestures (not customizable) for muscle memory
- No screen required (all haptic feedback)
- Battery-conscious (20Hz sampling, workout session)
- Confident gestures (prevent false positives)

---

## Key Context for Future Development

### Google Drive Service Account Incident (March 15, 2026)
**What Happened:**
- Attempted to use Google Drive service account for auto-upload
- Committed service account JSON to git (mistake)
- GitHub's secret scanner detected credentials
- Google automatically disabled the service account
- Cannot prevent this without Google org-level policy (unavailable to individuals)

**Lesson Learned:**
- Never commit service account credentials
- `.gitignore` updated to block all `*service-account*.json` files
- Firebase approach doesn't have this issue (no secrets in app)

**Current State:**
- Compromised service account disabled (no security risk)
- Google Drive approach abandoned
- Firebase implementation exists on separate branch

### Why HealthKit Workout Sessions?
**Problem:** watchOS aggressively suspends background apps to save battery.

**Solution:** Workout sessions get privileged background execution. Even when the Watch screen is off or the user switches apps, CoreMotion continues running and gestures are detected.

**Trade-off:** App appears as a "workout" in Activity rings. Acceptable for the use case (music control during activity).

**Alternative Considered:** Background app refresh (too unreliable, ~1-2 updates/hour).

### Why WatchConnectivity File Transfer (Not Messages)?
**For gesture commands:** Use `sendMessage()` (low latency, <200ms)

**For ML data:** Use `transferFile()` for the following reasons:
1. No payload size limit (messages capped at ~256KB)
2. Queues files for background transfer (messages require both devices awake)
3. Guaranteed delivery (messages can be dropped)

**Trade-off:** Higher latency (2-5 seconds typical), but that's fine for non-real-time data.

### Gesture Threshold Tuning Philosophy
**Current:** Hardcoded values in MotionManager.swift

**Why not configurable?**
- Prevents users from tuning themselves into false positives
- Maintains consistent UX across all users
- Forces us to build a good default (via ML model)

**Long-term:** Replace thresholds with ML model trained on diverse user data.

### Why Three Gestures (Not More)?
**Principle:** Minimal viable set that covers primary music controls.

**Trade-offs considered:**
- More gestures = harder to remember
- More gestures = higher false positive rate
- More gestures = cognitive load during activity

**Future expansion possible:** But only if user research shows clear demand.

---

## Questions to Ask When Starting a New Session

1. **What's the goal?** (Feature, bugfix, tuning, data collection)
2. **Which branch?** (`main` for share sheet, `firebase-integration` for auto-upload)
3. **Real hardware or simulator?** (Some features only work on real devices)
4. **Which part of the system?** (Watch sensors, iPhone playback, communication, ML pipeline)
5. **Is this blocked on data?** (ML model training requires collected sessions)

---

## Next Session Priorities (as of 2026-03-20)

**Immediate:**
- Recruit 5-10 beta testers for ML data collection
- Test data collection pipeline on real hardware
- Verify CSV labels match actual gestures performed

**Short-term:**
- Collect 50-100 labeled training sessions
- Begin exploratory data analysis in Python
- Design ML model architecture (Random Forest vs LSTM vs Create ML)

**Medium-term:**
- Train and evaluate ML model
- Integrate .mlmodel into Xcode
- Replace MotionManager thresholds with model inference

**Long-term:**
- Decide on Firebase vs share sheet based on tester count
- Polish for TestFlight beta (Phase 7)
- App Store preparation (Phase 8)

---

## Log Maintenance Guidelines

**When to add an entry:**
- After completing a major feature or phase
- After making an architectural decision
- After encountering a subtle bug (especially platform-specific)
- After research or experimentation (even if it didn't work)

**What to include:**
- Date and session type
- Context: Why this work, what problem it solves
- Work completed: Concrete deliverables
- Decisions made: Technical choices and reasoning
- Lessons learned: Gotchas, pitfalls, non-obvious behavior
- State left in: Where to pick up next time

**What to omit:**
- Line-by-line code changes (that's what git is for)
- Routine bug fixes (unless they reveal something important)
- Experiment details (unless they inform future work)

---

**Last Updated:** March 20, 2026  
**Next Review:** When Phase 4.1 (data collection) completes
