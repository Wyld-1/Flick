//
//  FlickIntents.swift
//  Flick
//
//  App Intents for native Shortcuts integration
//

import AppIntents
import MediaPlayer

// Next Track Intent
struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip to Next Track"
    static var description = IntentDescription("Skips to the next track")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        let player = MPMusicPlayerController.systemMusicPlayer
        player.skipToNextItem()
        return .result()
    }
}

// Previous Track Intent
struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip to Previous Track"
    static var description = IntentDescription("Skips to the previous track")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        let player = MPMusicPlayerController.systemMusicPlayer
        player.skipToPreviousItem()
        return .result()
    }
}

// Play/Pause Intent
struct PlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Play or Pause Music"
    static var description = IntentDescription("Toggles play/pause for music")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        let player = MPMusicPlayerController.systemMusicPlayer
        
        if player.playbackState == .playing {
            player.pause()
        } else {
            player.play()
        }
        
        return .result()
    }
}

// Shortcuts Provider
struct CodaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextTrackIntent(),
            phrases: ["Skip forward in \(.applicationName)"],
            shortTitle: "Next Track",
            systemImageName: "forward.fill"
        )
        
        AppShortcut(
            intent: PreviousTrackIntent(),
            phrases: ["Skip back in \(.applicationName)"],
            shortTitle: "Previous Track",
            systemImageName: "backward.fill"
        )
        
        AppShortcut(
            intent: PlayPauseIntent(),
            phrases: ["Play or pause in \(.applicationName)"],
            shortTitle: "Play/Pause",
            systemImageName: "playpause.fill"
        )
    }
}
