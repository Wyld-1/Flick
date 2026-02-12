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

// Constants that sync between devices
struct AppConstants {
    static let appVersion = "1.2"
    static let flickPurple = Color(red: 96/255, green: 0/255, blue: 247/255)
}

// Settings that sync between devices
struct AppSettings: Codable {
    var isTapEnabled: Bool
    var isFlickDirectionReversed: Bool
    var isTutorialCompleted: Bool
    
    var playbackMethod: PlaybackMethod
    
    var hasCompletedInitialSetup: Bool
    
    // Update default initializer
    static let `default` = AppSettings(
        isTapEnabled: false,
        isFlickDirectionReversed: false,
        isTutorialCompleted: false,
        playbackMethod: .appleMusic,
        hasCompletedInitialSetup: false
    )
}

// Helper to read/write settings via App Groups
class SharedSettings {
    private static let appGroupID = "group.flickplayback.SharedFiles"
    private static let settingsKey = "appSettings"
    
    private static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    static func load() -> AppSettings {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: settingsKey),
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
        defaults.set(data, forKey: settingsKey)
        
        // Notify Watch Connectivity to sync if needed
        WatchConnectivityManager.shared.syncSettings(settings)
    }
}
