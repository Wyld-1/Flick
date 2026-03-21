# Flick - Architecture

## High-Level System Design

```
┌─────────────────────────────────────────────┐
│          Apple Watch (watchOS)               │
│  ┌────────────────────────────────────────┐ │
│  │   MotionManager (Sensor Reading)        │ │
│  │   - CoreMotion API (20Hz polling)       │ │
│  │   - Gesture detection algorithms        │ │
│  │   - HealthKit workout session (bkgnd)   │ │
│  └─────────────────┬────────────────────────┘ │
│                    │                          │
│  ┌─────────────────▼────────────────────────┐ │
│  │   WatchConnectivityManager (Comms)      │ │
│  │   - Sends MediaCommand to iPhone        │ │
│  │   - Syncs settings bidirectionally      │ │
│  │   - Command queue + retry logic         │ │
│  └─────────────────┬────────────────────────┘ │
└────────────────────┼──────────────────────────┘
                     │ WatchConnectivity
                     │ (Bluetooth)
┌────────────────────▼──────────────────────────┐
│           iPhone (iOS)                         │
│  ┌────────────────────────────────────────────┐ │
│  │   WatchConnectivityManager (Receiver)     │ │
│  │   - Receives MediaCommand from Watch      │ │
│  │   - Routes to iOSMediaManager             │ │
│  └─────────────────┬──────────────────────────┘ │
│                    │                          │
│  ┌─────────────────▼──────────────────────────┐ │
│  │   iOSMediaManager (Playback Control)      │ │
│  │   - Apple Music (MPMusicPlayerController) │ │
│  │   - Spotify (SPTAppRemote SDK)            │ │
│  │   - iOS Shortcuts (URL scheme)            │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘

             Shared Source of Truth
┌─────────────────────────────────────────────────┐
│   App Group Container (SharedSettings)          │
│   - Playback method (Apple Music/Spotify)       │
│   - Data collection state (off/recording/sync)  │
│   - Tutorial completion, settings               │
└─────────────────────────────────────────────────┘
```

## Core Data Flow

### Gesture Detection → Media Control

```
1. Watch: MotionManager detects rotation > 1.8 rad/s
2. Watch: Determines gesture type (FlickLeft/Right/PlayPause)
3. Watch: Maps gesture → MediaCommand enum
4. Watch: WatchConnectivityManager.sendMediaCommand()
   - If reachable: Send immediately via WCSession.sendMessage
   - If unreachable: Queue command, retry every 2s
5. iPhone: WatchConnectivityManager receives message
6. iPhone: Routes to iOSMediaManager.handleCommand()
7. iPhone: Based on PlaybackMethod setting:
   - Apple Music → MPMusicPlayerController.skipToNextItem()
   - Spotify → SPTAppRemote.playerAPI.skip(toNext:)
   - Shortcuts → Launch iOS Shortcut via URL scheme
8. iPhone: Plays system haptic feedback
9. User: Hears track change, feels haptic
```

### ML Data Collection Pipeline

```
┌──────────────────────────────────────────────┐
│ iPhone: User presses "BEGIN RECORDING"       │
│ → Sets SharedSettings.dataCollectionState    │
│    to .recording                              │
└─────────────────┬────────────────────────────┘
                  │
        ┌─────────▼──────────┐
        │  WatchConnectivity  │
        │  syncs settings     │
        └─────────┬───────────┘
                  │
┌─────────────────▼────────────────────────────┐
│ Watch: DataCollectionManager observes state  │
│ change via NotificationCenter                │
│ → Starts CoreMotion at 50Hz                  │
│ → Records MotionSample array                 │
│   (timestamp, rotation, gravity, accel)      │
└─────────────────┬────────────────────────────┘
                  │
┌─────────────────▼────────────────────────────┐
│ iPhone: User holds gesture buttons while     │
│ performing motions                            │
│ → DataCollectionCoordinator records          │
│   GestureLabel (startTime, endTime, type)    │
└─────────────────┬────────────────────────────┘
                  │
┌─────────────────▼────────────────────────────┐
│ iPhone: User presses "FINISH RECORDING"      │
│ → Sets dataCollectionState to .syncing       │
└─────────────────┬────────────────────────────┘
                  │
┌─────────────────▼────────────────────────────┐
│ Watch: Observes state change                 │
│ → Stops CoreMotion                           │
│ → Encodes MotionSample[] to JSON             │
│ → WCSession.transferFile() to iPhone         │
└─────────────────┬────────────────────────────┘
                  │
┌─────────────────▼────────────────────────────┐
│ iPhone: WatchConnectivityManager receives    │
│ file via didReceive(file:)                   │
│ → Decodes JSON to MotionSample array         │
│ → Posts "WatchDataReceived" notification     │
└─────────────────┬────────────────────────────┘
                  │
┌─────────────────▼────────────────────────────┐
│ iPhone: DataCollectionCoordinator receives   │
│ notification                                  │
│ → Matches MotionSample timestamps with       │
│   GestureLabel time windows                  │
│ → Generates CSV with labeled sensor data     │
│ → Presents iOS share sheet                   │
│ → User saves to Files/AirDrop/email          │
└──────────────────────────────────────────────┘
```

**CSV Format:**
```
timestamp,rotX,rotY,rotZ,gravX,gravY,gravZ,userAccelX,userAccelY,userAccelZ,label
1710960123.45,0.1,0.2,-0.1,0.0,1.0,0.0,0.05,0.03,-0.02,None
1710960123.46,0.5,-0.3,0.2,0.0,1.0,0.0,0.15,0.08,0.12,FlickLeft
```

## SharedTypes as Single Source of Truth

**Philosophy:** All shared state lives in `SharedTypes.swift` and is synchronized via App Groups. Neither platform maintains duplicate state.

**Key types:**
```swift
enum MediaCommand: String, Codable {
    case nextTrack, previousTrack, playPause
}

enum PlaybackMethod: String, Codable {
    case appleMusic, spotify, shortcuts
}

enum DataCollectionState: String, Codable {
    case off, recording, syncing
}

struct AppSettings: Codable {
    var playbackMethod: PlaybackMethod
    var dataCollectionState: DataCollectionState
    // ... other settings
}
```

**Storage mechanism:**
```swift
class SharedSettings {
    private static let appGroupID = "group.flickplayback.SharedFiles"
    
    static func load() -> AppSettings { ... }
    static func save(_ settings: AppSettings) {
        // 1. Write to App Group UserDefaults
        // 2. Trigger WatchConnectivityManager.syncSettings()
    }
}
```

**State observers:**
- Both platforms observe `NotificationCenter` for "SettingsDidUpdate"
- When settings change, each platform reacts accordingly
- iPhone controls collection state, Watch observes and responds

## File & Folder Structure

```
Flick/
├── CommunicationFramework/          # Shared between iOS & watchOS
│   ├── SharedTypes.swift            # Single source of truth types
│   ├── WatchConnectivityManager.swift  # Bidirectional sync + messaging
│   └── Flick-Bridging-Header.h     # ObjC bridge (for Spotify SDK)
│
├── Flick/ (iOS Target)
│   ├── FlickApp.swift               # App entry point, state routing
│   ├── Managers/
│   │   ├── AppStateManager.swift   # Onboarding flow state machine
│   │   ├── iOSMediaManager.swift   # Media control (Apple Music, Spotify, Shortcuts)
│   │   └── DataCollectionCoordinator.swift  # iPhone side of ML pipeline
│   ├── Views/
│   │   ├── WelcomeView.swift       # Initial authorization screen
│   │   ├── PlayerSetupView.swift   # Choose playback method
│   │   ├── ContinueOnWatchView.swift  # Tutorial completion blocker
│   │   ├── MainView.swift          # Primary iPhone interface
│   │   ├── DataCollectionView.swift   # ML data labeling UI
│   │   └── Shared UI Elements/     # Reusable components
│   └── Assets.xcassets
│
├── Flick Watch App/ (watchOS Target)
│   ├── FlickApp.swift               # Watch app entry point
│   ├── Managers/
│   │   ├── AppStateManager.swift   # Tutorial state machine
│   │   ├── MotionManager.swift     # Gesture detection engine
│   │   └── DataCollectionManager.swift  # Watch side of ML pipeline
│   ├── Views/
│   │   ├── ContentView.swift       # Main gesture control UI
│   │   ├── TutorialView.swift      # Interactive gesture training
│   │   ├── DataCollectionView.swift   # ML recording UI
│   │   └── SettingsView.swift      # Playback method selector
│   └── Assets.xcassets
│
├── Flick.xcodeproj/                 # Xcode project configuration
├── ios-sdk-5.0.1/                   # Spotify iOS SDK (binary framework)
└── Docs/                            # This documentation
```

## Key Dependencies

### External
- **HealthKit** (watchOS): Workout sessions for background execution
- **CoreMotion** (watchOS): Accelerometer, gyroscope, gravity sensors
- **WatchConnectivity** (both): Bluetooth messaging and file transfer
- **MediaPlayer** (iOS): Apple Music control via MPMusicPlayerController
- **Spotify iOS SDK 5.0.1** (iOS): `SPTAppRemote` for Spotify control
- **UIKit** (iOS): Share sheet for ML data export

### Internal
- **App Groups**: `group.flickplayback.SharedFiles` for SharedSettings
- **URL Schemes**: `flick://callback` for Spotify OAuth
- **Shortcuts**: URL scheme integration for user-created automations

## Critical Design Decisions

### Why HealthKit Workout Sessions?
**Problem:** watchOS suspends background apps aggressively.  
**Solution:** Workout sessions get privileged background execution. Even when the screen is off or the user switches apps, CoreMotion continues running.  
**Trade-off:** Appears as "workout" in Activity rings. Acceptable for the use case.

### Why WatchConnectivity File Transfer (Not Messages)?
**Problem:** `sendMessage()` requires both devices to be reachable and has ~256KB payload limit.  
**Solution:** `transferFile()` queues files and transfers when possible, no size limit.  
**Use case:** ML training data can be 100KB+ of JSON (thousands of sensor samples).  
**Trade-off:** Slower (async), but guaranteed delivery.

### Why Hardcoded Thresholds (Not ML Model)?
**Current:** Gesture detection uses fixed thresholds (e.g., `TWIST_THRESHOLD = 1.8 rad/s`).  
**Reason:** No training data yet. ML pipeline is in place to collect data for future model.  
**Future:** Replace hardcoded logic with CoreML model trained on collected data.

### Why Three Playback Methods?
- **Apple Music:** Built-in, requires no setup, works immediately
- **Spotify:** Most popular third-party service, requires OAuth but provides best UX
- **Shortcuts:** Escape hatch for any other player (YouTube Music, etc.) via user automation

## Communication Patterns

### Command Sending (Watch → iPhone)
```swift
// Immediate delivery (requires both devices awake)
WatchConnectivityManager.sendMediaCommand(.nextTrack)
  → WCSession.sendMessage(_:replyHandler:errorHandler:)
  
// On failure: Queue and retry
  → commandQueue.append(command)
  → Timer fires every 2s to retry
  → Clear queue on successful send
```

### Settings Sync (Bidirectional)
```swift
// Either platform can update settings
SharedSettings.save(newSettings)
  → UserDefaults(appGroupID).set()
  → WCSession.updateApplicationContext()
  → Other platform receives in didReceiveApplicationContext()
  → Posts NotificationCenter "SettingsDidUpdate"
  → Observers react to state change
```

### File Transfer (Watch → iPhone)
```swift
// Watch encodes and sends
WCSession.transferFile(fileURL, metadata: ["type": "motionData"])
  → File queued for background transfer
  → Progress observed via KVO on WCSessionFileTransfer.progress

// iPhone receives
didReceive(file: WCSessionFile)
  → Decode JSON from file.fileURL
  → Post NotificationCenter with data
  → Coordinator processes and exports CSV
```

## State Machine Diagrams

### Onboarding Flow (iPhone)
```
.welcome
  → User grants HealthKit permission
  ↓
.playbackChoice
  → User selects Apple Music / Spotify / Shortcuts
  → (Spotify: OAuth flow via Safari)
  ↓
.waitingForWatch
  → Blocking screen until Watch completes tutorial
  → Observes SharedSettings.isTutorialCompleted
  ↓
.main
  → Full app functionality unlocked
```

### Data Collection State (Shared)
```
.off (idle)
  → iPhone: User presses "BEGIN RECORDING"
  ↓
.recording
  → iPhone: Labels gestures with button presses
  → Watch: Collects MotionSample array at 50Hz
  → iPhone: User presses "FINISH RECORDING"
  ↓
.syncing
  → Watch: Encodes JSON, sends file to iPhone
  → iPhone: Shows "Transferring data: X%"
  → iPhone: Receives file, generates CSV
  → iPhone: Presents share sheet
  ↓
.off (reset after sync completes)
```

## Performance Characteristics

**Gesture Detection Latency:**
- Sensor polling: 50ms (20Hz)
- Detection algorithm: <1ms
- WatchConnectivity send: 50-200ms (varies with BT)
- iPhone command handling: <10ms
- **Total:** ~100-250ms ear-to-ear

**Battery Impact:**
- Background workout session: ~5-10% per hour
- Comparable to actual workout tracking
- Pauses automatically when app is suspended

**Data Collection:**
- 50Hz sampling = 50 samples/second
- 10 bytes per sample (rough)
- 3-minute recording = 9,000 samples = ~90KB JSON
- Typical file transfer: 2-5 seconds over Bluetooth
