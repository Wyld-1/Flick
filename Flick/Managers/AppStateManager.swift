//
//  AppStateManager.swift
//  Flick iOS
//
//  Manages app state and view routing
//

import Foundation
import Combine
import UIKit

enum AppState {
    case welcome
    case playbackChoice
    case waitingForWatch
    case main
}

class AppStateManager: ObservableObject {
    @Published var currentState: AppState
    
    init() {
        // 1. Initialize Managers
        _ = WatchConnectivityManager.shared
        _ = iOSMediaManager.shared
        HapticManager.shared.prepare()
        
        // 2. Load Data
        let settings = SharedSettings.load()
        
        // 3. Determine Initial State - BOTH must be true
        if settings.isTutorialCompleted && settings.hasCompletedInitialSetup {
            self.currentState = .main
        } else if settings.hasCompletedInitialSetup {
            self.currentState = .waitingForWatch
        } else {
            self.currentState = .welcome
        }
        
        // 4. Listen for Watch updates
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let freshSettings = SharedSettings.load()
            
            // Only advance when BOTH are complete
            if freshSettings.isTutorialCompleted && freshSettings.hasCompletedInitialSetup {
                self.currentState = .main
            }
        }
    }
    
    func completeWelcome() {
        currentState = .playbackChoice
    }
    
    func completePlaybackChoice(useShortcuts: Bool) {
        // 1. Save preferences to Shared Settings
        var settings = SharedSettings.load()
        settings.useShortcutsForPlayback = useShortcuts
        settings.hasCompletedInitialSetup = true  // ← Mark iOS setup complete
        SharedSettings.save(settings)
        
        print("📱 iOS setup complete. Watch tutorial complete: \(settings.isTutorialCompleted)")
        
        // 2. Check if BOTH are complete
        if settings.isTutorialCompleted {
            currentState = .main
        } else {
            currentState = .waitingForWatch
        }
    }
    
    func goToMain() {
        currentState = .main
    }
    
    // MARK: - Debug Helper
    func resetForDebug() {
        // Reset BOTH flags in shared storage
        var settings = SharedSettings.load()
        settings.hasCompletedInitialSetup = false
        settings.isTutorialCompleted = false
        SharedSettings.save(settings)
        
        currentState = .welcome
        
        print("🔄 Reset to welcome. Both flags cleared.")
    }
}
