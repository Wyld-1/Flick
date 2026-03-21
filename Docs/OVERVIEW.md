# Flick - Overview

## What It Is

Flick is a gesture-based music controller for Apple Watch that lets you control media playback without looking at your device or fumbling with tiny buttons. The app detects natural wrist movements and translates them into media commands.

## The Core Concept

**Three simple gestures, zero screen time:**
- **Flick left** (counterclockwise wrist twist) → Next track
- **Flick right** (clockwise wrist twist) → Previous track
- **Hold upside-down** (rotate wrist 180°, hold for 1.2s) → Play/Pause

The Watch continuously monitors motion sensors in the background via a HealthKit workout session. When a gesture is detected, it sends a command to the paired iPhone, which controls the active music player.

## Why It Exists

**The problem:** Controlling music while skiing, biking, or doing anything active is annoying. Pulling out your phone is cold and impractical. Tapping AirPod stems with gloves doesn't work. Even the Apple Watch UI requires looking down and precise taps.

**The solution:** Physical gestures you can do without thinking. The iPod Shuffle had the right idea with tactile controls — Flick brings that simplicity to modern devices, but better: no buttons to find, no screen to see, just move your wrist.

## Target Platforms

- **watchOS 26+** (primary interface, runs continuously in background)
- **iOS 26+** (companion app, handles media control and setup)

**Platform roles:**
- **Watch:** Gesture detection, sensor reading, data collection for ML training
- **iPhone:** Media playback control (Apple Music, Spotify, Shortcuts), onboarding flow, ML data labeling

## The Gesture Philosophy

**Design principles:**
1. **Confident, not subtle** — Gestures require clear intent (rotation > 1.8 rad/s, hold for 1.2s). Prevents accidental triggers while still being easy to execute.
2. **No screen required** — You should never need to look at the Watch. Haptic feedback confirms every action.
3. **Memorable mapping** — Direction-based gestures map to sequential actions (left/right = prev/next). The upside-down hold is distinctive enough to be unmistakable.
4. **Battery-conscious** — Runs as a workout session for background execution, but only samples sensors at 20Hz. Pauses automatically when OS suspends the app.

## Product Vision

**Current state:** Fully functional music controller with ML data collection system for training gesture recognition models.

**Long-term vision:** 
- Custom ML model trained on user data (replacing hardcoded thresholds)
- Adaptive detection that learns individual movement patterns
- Potential expansion to additional gestures or use cases
- Public release via TestFlight/App Store

**Not in scope:**
- Gesture customization (gestures are fixed by design for consistency)
- Non-music use cases (focus is music control during activity)
- Standalone Watch app (iPhone required for media control APIs)
