**README.md**

# Coda
Coda is the second version of a gesture-based music controller built for Apple Watch. The goal is to remove the need to open your device or fumble with tiny buttons when you just want to skip a song.

## How it works
Use three simple wrist gestures control your media:
- **Flick left**: Next track
- **Flick right**: Previous track  
- **Hold upside-down**: Play/Pause

The app uses your Watch's accelerometer and gyroscope to detect these movements, then sends a command to iPhone to take action.

## Why I made this
I wanted something dead simple for controlling music while skiing, biking, or being active. Pulling out my phone on the slopes is cold and annoying. Trying to tap AirPod controls with gloves on doesn't work all that great.
The iPod Shuffle had the right idea with physical simplicity all those years ago, but I wanted to make it modern and take it a step further.

## Current status
Gestures, UI, and app flow work. Taking media actions (skipping, pausing, playing, etc.) are in progress as the iOS app is being developed.
After testing, I may add double flick detection and link to "Like song" or volume control.

## Installation
Want to test it yourself? Follow the steps below.

**Step 1: Clone this repo into an Xcode project**

- You must have Xcode 26.0 or later

**Step 2: Pair the Watch with your iPhone**
- The Watch must be paired to an iPhone first
- That iPhone needs to be signed into the same Apple ID you're using in Xcode

**Step 3: Connect the iPhone to your Mac**
- Use a USB cable (or enable wireless debugging)
- The Watch doesn't connect directly. Instead, it goes through the paired iPhone

**Step 4: Enable Developer Mode on both devices**

*On iPhone:*
- Settings → Privacy & Security → Developer Mode → Turn ON
- Restart iPhone when prompted

*On Apple Watch:*
- Settings → Privacy & Security → Developer Mode → Turn ON
- Restart Watch when prompted

**Step 5: Trust the computer**
- When you plug in the iPhone, you'll get a "Trust This Computer" prompt
- Tap Trust and enter passcode

**Step 6: Select Watch as destination in Xcode**
- At the top of Xcode (next to the play/stop buttons), click the device dropdown
- You should see the iPhone and below it, the paired Apple Watch
- Select the Watch (it'll say something like "Apple Watch Series X - [Owner's Name]'s Watch")

**Troubleshooting:**
- If Watch doesn't appear: Unplug iPhone, restart Xcode, plug back in
- Make sure Watch and iPhone are both unlocked
- Check that both have Developer Mode enabled
- Sometimes it takes 30-60 seconds for Watch to show up after connecting

**Wireless option (once set up):**
- Window → Devices and Simulators
- Select your iPhone → Check "Connect via network"

---

Coda is made for people who don't want to break their flow just to skip a song.
