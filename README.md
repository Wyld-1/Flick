# Flick
Flick is the second version of a gesture-based music controller built for Apple Watch. The goal is to remove the need to open your device or fumble with tiny buttons when you just want to skip a song.

---
## Almost In Beta!

**TestFlight release** is coming soon! We are looking for beta testers to collect ML training data.
See the *Contributing to ML Training* for details.

---

## How Flick Works

Three natural wrist movements control your media:

- **Flick left** (counterclockwise twist) → Next track
- **Flick right** (clockwise twist) → Previous track  
- **Hold upside-down** (rotate wrist 180°, hold 1.2s) → Play/Pause

The Watch continuously monitors motion sensors in the background. When you perform a gesture, it sends a command to your iPhone, which controls your active music player.

## Supported Music Players

- **Apple Music** — Built-in, works immediately
- **Spotify** — Full integration via Spotify Connect
- **iOS Shortcuts** — Control any player, but requiers iPhone to be unlocked. **DEBUG mode only**

## Requierments

- **iPhone**, running iOS 26.0+
- **Apple Watch**, running watchOS 26.0+
- Either an **Apple Music** or **Spotify** subscription

**To install, either:**
- **TestFlight** installed on your devices *(Coming soon)*
- **Xcode** on your Mac, and **Developer Mode** enabled on both devices
See the *Instalation* section for details.

---

## Current Status

**TestFlight Beta app coming soon!**
**Phase:** Collecting sensor data to train a gesture-detection ML model
**Version:** 1.3 (March 2026)

### ✅ What Works
- Real-time gesture detection on Apple Watch
- Media playback control (Apple Music, Spotify, Shortcuts)
- Background execution during activity
- Bidirectional settings sync between devices
- ML training data collection pipeline

### 🔧 In Progress
- Training custom ML model for gesture recognition (currently uses hardcoded thresholds)
- Collecting labeled sensor data from beta testers
- Tuning detection accuracy across different users

### 🎯 What's Next
- Custom CoreML model to replace hardcoded detection logic
- Public TestFlight beta (targeting mid-2026)
- App Store release (targeting late 2026)

---

## Contributing to ML Training

After installing Flick:

1. Open the iPhone app
2. Navigate to "Data Collection"
3. Press "BEGIN RECORDING"
4. Hold a gesture button (Flick Left/Right/Upside Down) while performing the motion
5. Press "FINISH RECORDING" when done
6. Share the generated CSV file via AirDrop, Files, or email

**What we're collecting:**
- Motion sensor data (rotation, gravity, acceleration) at 50Hz
- Timestamped labels for which gesture was performed when
- NO personal data, location, or media library information

**Data format:**
```csv
timestamp,rotX,rotY,rotZ,gravX,gravY,gravZ,userAccelX,userAccelY,userAccelZ,label
1710960123.45,0.1,0.2,-0.1,0.0,1.0,0.0,0.05,0.03,-0.02,None
1710960123.46,0.5,-0.3,0.2,0.0,1.0,0.0,0.15,0.08,0.12,FlickLeft
```

---

## Installation (For Beta Testers)

**TestFlight app coming soon!**

### Prerequisites
- Xcode 26.0 or later
- Apple Watch (Series 4+) running watchOS 26+
- iPhone running iOS 26+
- Apple Developer account (free tier works)

### Setup Steps

**1. Clone the repository**
```bash
git clone https://github.com/yourusername/flick.git
cd flick
```

**2. Pair your Watch with your iPhone**
- The Watch must be paired to the iPhone you'll use for testing
- Both devices must be signed into the same Apple ID

**3. Connect iPhone to your Mac**
- Use USB cable or enable wireless debugging
- The Watch connects *through* the paired iPhone

**4. Enable Developer Mode**

On iPhone:
- Settings → Privacy & Security → Developer Mode → Turn ON
- Restart when prompted

On Apple Watch:
- Settings → Privacy & Security → Developer Mode → Turn ON
- Restart when prompted

**5. Trust your computer**
- When you plug in the iPhone, tap "Trust This Computer"
- Enter iPhone passcode

**6. Select Watch as build target**
- Open `Flick.xcodeproj` in Xcode
- In the toolbar, click the device dropdown
- Select your Apple Watch (appears under your iPhone's name)

**7. Build and run**
- Press ⌘R or click the play button
- App will install on both iPhone and Watch
- Follow the onboarding flow to grant permissions

### Troubleshooting
- **Watch doesn't appear:** Unplug iPhone, restart Xcode, plug back in
- **Build fails:** Ensure both devices have Developer Mode enabled and are unlocked
- **Gestures not working:** Real hardware required (simulator has no sensors)

---

## Architecture Overview

```
Apple Watch (watchOS)
├── MotionManager: Reads sensors, detects gestures
├── DataCollectionManager: Records training data
└── WatchConnectivityManager: Sends commands to iPhone

iPhone (iOS)
├── iOSMediaManager: Controls music players
├── DataCollectionCoordinator: Labels training data
└── WatchConnectivityManager: Receives commands from Watch

Shared (CommunicationFramework)
├── SharedTypes: Single source of truth for types
└── App Groups: Settings sync between devices
```

**Key data flows:**
1. **Gesture → Playback:** Watch detects motion → Sends MediaCommand → iPhone controls player
2. **ML Data Collection:** Watch records sensors → Transfers to iPhone → iPhone labels + exports CSV

For detailed architecture documentation, see [`Docs/ARCHITECTURE.md`](Docs/ARCHITECTURE.md).

---

## Project Structure

```
Flick/
├── Docs/                      # Development documentation
│   ├── OVERVIEW.md           # Product vision and philosophy
│   ├── ARCHITECTURE.md       # System design and data flows
│   ├── STATUS.md             # Current build state and bugs
│   ├── ROADMAP.md            # Feature roadmap and phases
│   └── SESSION_LOG.md        # Development session history
│
├── CommunicationFramework/    # Shared iOS/watchOS code
│   ├── SharedTypes.swift     # Type definitions
│   └── WatchConnectivityManager.swift
│
├── Flick/                     # iPhone app (iOS)
│   ├── Managers/
│   │   ├── iOSMediaManager.swift
│   │   └── DataCollectionCoordinator.swift
│   └── Views/
│
├── Flick Watch App/           # Watch app (watchOS)
│   ├── Managers/
│   │   ├── MotionManager.swift
│   │   └── DataCollectionManager.swift
│   └── Views/
│
└── README.md                  # This file
```

---

## Technical Stack

- **Language:** Swift 5.9+
- **Platforms:** watchOS 26+, iOS 26+
- **Frameworks:**
  - CoreMotion (sensor reading)
  - HealthKit (background execution)
  - WatchConnectivity (device communication)
  - MediaPlayer (Apple Music control)
  - Spotify iOS SDK 5.0.1 (Spotify control)
- **Future:** CoreML (gesture recognition model)

---

## Documentation

**For developers:**
- [**OVERVIEW**](Docs/OVERVIEW.md) — Product vision, gesture philosophy
- [**ARCHITECTURE**](Docs/ARCHITECTURE.md) — System design, data flows, communication patterns
- [**STATUS**](Docs/STATUS.md) — Current build state, working/broken features *(Start here!)*
- [**ROADMAP**](Docs/ROADMAP.md) — Feature phases and completion status
- [**SESSION_LOG**](Docs/SESSION_LOG.md) — Development history and key decisions

**Quick links:**
- [Bug log](Docs/STATUS.md#-bug-log)
- [Known issues](Docs/STATUS.md#️-partially-working--known-issues)
- [ML training pipeline](Docs/ARCHITECTURE.md#ml-data-collection-pipeline)

---

## License

*To be determined — project currently in private development.*

---

**Flick is made for people who don't want to break their flow just to skip a song.**
