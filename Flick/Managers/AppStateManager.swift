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
    
    // Store observer token to prevent premature deallocation
    private var settingsObserver: NSObjectProtocol?
    
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
        
        // 4. Properly store observer and add thread safety
        settingsObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            
            // Prevent concurrent updates
            DispatchQueue.main.async {
                let freshSettings = SharedSettings.load()
                
                // Only advance when BOTH are complete
                if freshSettings.isTutorialCompleted && freshSettings.hasCompletedInitialSetup {
                    print("📱 Both setup flags complete - advancing to main")
                    self.currentState = .main
                } else {
                    print("📱 Settings updated but not both complete yet")
                }
            }
        }
    }
    
    deinit {
        // Clean up observer
        if let observer = settingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func completeWelcome() {
        currentState = .playbackChoice
    }
    
    func completePlaybackChoice(method: PlaybackMethod) {
        var settings = SharedSettings.load()
        
        settings.playbackMethod = method
        settings.hasCompletedInitialSetup = true
        
        SharedSettings.save(settings)
        
        print("📱 iOS setup complete. Playback Method: \(method)")
        
        // Check if BOTH are complete
        if settings.isTutorialCompleted {
            currentState = .main
        } else {
            currentState = .waitingForWatch
        }
    }
    
    func goToMain() {
        DispatchQueue.main.async { [weak self] in
            self?.currentState = .main
        }
    }
    
    // MARK: - Debug Helper
    func resetForDebug() {
        // Reset BOTH flags in shared storage
        var settings = SharedSettings.load()
        settings.hasCompletedInitialSetup = false
        settings.isTutorialCompleted = false
        SharedSettings.save(settings)
        
        DispatchQueue.main.async { [weak self] in
            self?.currentState = .welcome
        }
        
        print("🔄 Reset to welcome. Both flags cleared.")
    }
}
