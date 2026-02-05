//
//  MediaManager.swift
//  Flick
//
//  Created by Liam Lefohn on 1/27/26.
//
// Controls media playback

import Foundation
import MediaPlayer
import WatchKit
import Combine

class MediaManager: ObservableObject {
    private let commandCenter = MPRemoteCommandCenter.shared()
    
    init() {
        // Enable the commands
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
    }
    
    func handleGesture(_ gesture: GestureType) {
        switch gesture {
        case .nextTrack:
            WKInterfaceDevice.current().play(.success)
            commandCenter.nextTrackCommand.perform(nil)
            
        case .previousTrack:
            WKInterfaceDevice.current().play(.success)
            commandCenter.previousTrackCommand.perform(nil)
            
        case .playPause:
            WKInterfaceDevice.current().play(.success)
            commandCenter.togglePlayPauseCommand.perform(nil)
            
        case .none:
            break
        }
    }
}
