//
//  iOSMediaManager.swift
//  Flick
//
//  Handles media playback on iPhone
//

import Foundation
import MediaPlayer
import UIKit
import Combine
#if DEBUG
import AudioToolbox
#endif

class iOSMediaManager: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    
    static let shared = iOSMediaManager()
    
    private let appleMusicPlayer = MPMusicPlayerController.systemMusicPlayer
    
    // Shortcut names
    private let shortcutNames = [
        "nextTrack": "FlickNext",
        "previousTrack": "FlickPrevious",
        "playPause": "FlickPlayPause"
    ]
    
    private init() {
        print("📱 iOS MediaManager initialized")
    }
    
    func handleCommand(_ command: MediaCommand) {
        print("📱 Handling command: \(command.rawValue)")
        
        #if DEBUG
        // Haptic feedback
        AudioServicesPlaySystemSound(1520)
        //HapticManager.shared.playSuccess()
        #endif
        
        // Check which playback method to use
        let settings = SharedSettings.load()
        
        if settings.useShortcutsForPlayback {
            handleCommandViaShortcuts(command)
        } else {
            handleCommandViaAppleMusic(command)
        }
        
        // Notify UI
        NotificationCenter.default.post(
            name: NSNotification.Name("CommandReceived"),
            object: command
        )
    }
    
    // MARK: - Apple Music API Method
    private func handleCommandViaAppleMusic(_ command: MediaCommand) {
        print("📱 Using Apple Music API")
        
        switch command {
        case .nextTrack:
            appleMusicPlayer.skipToNextItem()
        case .previousTrack:
            appleMusicPlayer.skipToPreviousItem()
        case .playPause:
            if appleMusicPlayer.playbackState == .playing {
                appleMusicPlayer.pause()
            } else {
                appleMusicPlayer.play()
            }
        }
    }
    
    // MARK: - Shortcuts Method
    private func handleCommandViaShortcuts(_ command: MediaCommand) {
        print("📱 Using Shortcuts")
        
        let shortcutName: String
        switch command {
        case .nextTrack:
            shortcutName = shortcutNames["nextTrack"]!
        case .previousTrack:
            shortcutName = shortcutNames["previousTrack"]!
        case .playPause:
            shortcutName = shortcutNames["playPause"]!
        }
        
        runShortcut(named: shortcutName)
    }
    
    private func runShortcut(named name: String) {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://run-shortcut?name=\(encodedName)") else {
            return
        }
        
        UIApplication.shared.open(url, options: [:]) { success in
            if success {
                print("✅ Shortcut '\(name)' triggered")
            } else {
                print("❌ Failed to trigger shortcut '\(name)' - likely does not exist")
                // Inform the user physically if the shortcut is gone
                DispatchQueue.main.async {
                    HapticManager.shared.playWarning()
                }
            }
        }
    }
    
    // Check if Shortcuts app is available
    func canUseShortcuts() -> Bool {
        guard let url = URL(string: "shortcuts://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
