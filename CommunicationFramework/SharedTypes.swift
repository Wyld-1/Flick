//
//  SharedTypes.swift
//  Flick
//
//  Shared between iOS and watchOS targets
//

import Foundation

// Commands that can be sent from Watch to iPhone
enum MediaCommand: String, Codable {
    case nextTrack
    case previousTrack
    case playPause
}

// Settings that sync between devices
struct AppSettings: Codable {
    var isTapEnabled: Bool
    var isFlickDirectionReversed: Bool
    var isTutorialCompleted: Bool
    var useShortcutsForPlayback: Bool
    var hasCompletedInitialSetup: Bool
    var appVersion: String
    
    static let `default` = AppSettings(
        isTapEnabled: false,
        isFlickDirectionReversed: false,
        isTutorialCompleted: false,
        useShortcutsForPlayback: false,
        hasCompletedInitialSetup: false,
        appVersion: "1.1"
    )
}

// Helper to read/write settings via App Groups
class SharedSettings {
    private static let appGroupID = "group.codaplayback.SharedFiles"
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
        
        // Notify Watch Connectivity to sync
        WatchConnectivityManager.shared.syncSettings(settings)
    }
}
