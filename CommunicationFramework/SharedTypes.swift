//
//  SharedTypes.swift
//  Flick
//
//  Shared between iOS and watchOS targets
//

import Foundation
import SwiftUI

// Commands that can be sent from Watch to iPhone
enum MediaCommand: String, Codable {
    case nextTrack
    case previousTrack
    case playPause
}

enum PlaybackMethod: String, Codable {
    case appleMusic
    case spotify
    case shortcuts
}

// iPhone controls this state; Watch observes and responds
enum DataCollectionState: String, Codable {
    case off        // Not collecting data
    case recording  // Watch is collecting sensor data  
    case syncing    // Watch is encoding and sending data to iPhone
}

// Constants that sync between devices
struct AppConstants {
    static let appVersion = "Beta 1"
    static let flickPurple = Color(red: 96/255, green: 0/255, blue: 247/255)
}

// MARK: - ML Data Collection

// Motion sample from Watch sensors
struct MotionSample: Codable {
    let timestamp: TimeInterval  // Seconds since reference date
    let rotationX: Double
    let rotationY: Double
    let rotationZ: Double
    let gravityX: Double
    let gravityY: Double
    let gravityZ: Double
    let userAccelX: Double
    let userAccelY: Double
    let userAccelZ: Double
}

// Gesture label from iPhone button presses
struct GestureLabel: Codable {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let gestureType: String  // "FlickLeft", "FlickRight", "HoldUpsideDown"
}

// MARK: - Settings

// Settings that sync between devices
struct AppSettings: Codable {
    var isTapEnabled: Bool
    var isFlickDirectionReversed: Bool
    var isTutorialCompleted: Bool
    
    var playbackMethod: PlaybackMethod
    
    var hasCompletedInitialSetup: Bool
    
    // Data collection state - iPhone controls, Watch observes
    var dataCollectionState: DataCollectionState
    
    static let `default` = AppSettings(
        isTapEnabled: false,
        isFlickDirectionReversed: false,
        isTutorialCompleted: false,
        playbackMethod: .appleMusic,
        hasCompletedInitialSetup: false,
        dataCollectionState: .off
    )
}

// Helper to read/write settings via App Groups
class SharedSettings {
    private static let APP_GROUP_ID = "group.flickplayback.SharedFiles"
    private static let SETTINGS_KEY = "appSettings"
    
    private static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: APP_GROUP_ID)
    }
    
    static func load() -> AppSettings {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: SETTINGS_KEY),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    static func save(_ settings: AppSettings) {
        guard let defaults = userDefaults,
              let data = try? JSONEncoder().encode(settings) else {
            return
        }
        defaults.set(data, forKey: SETTINGS_KEY)
        WatchConnectivityManager.shared.syncSettings(settings)
    }
}
