//
//  MediaManager.swift
//  Coda Watch App
//
//  Sends media commands to iPhone
//

import Foundation
import WatchKit
import Combine

class MediaManager: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    
    @Published var currentTrack: String = "Ready"
    
    func handleGesture(_ gesture: GestureType) {
        let command: MediaCommand
        
        switch gesture {
        case .nextTrack:
            command = .nextTrack
        case .previousTrack:
            command = .previousTrack
        case .playPause:
            command = .playPause
        case .none:
            return
        }
        
        // Send command to iPhone
        WatchConnectivityManager.shared.sendMediaCommand(command)
        
        // Immediate haptic feedback
        WKInterfaceDevice.current().play(.success)
    }
}
