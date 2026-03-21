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
    
    private var mSettingsObserver: NSObjectProtocol?
    
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
        
        mSettingsObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let freshSettings = SharedSettings.load()
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
        if let observer = mSettingsObserver {
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
        print("📱 iOS setup complete. Playback method: \(method)")
        currentState = settings.isTutorialCompleted ? .main : .waitingForWatch
    }
    
    func goToMain() {
        DispatchQueue.main.async { [weak self] in
            self?.currentState = .main
        }
    }
    
    func resetForDebug() {
        var settings = SharedSettings.load()
        settings.hasCompletedInitialSetup = false
        settings.isTutorialCompleted = false
        settings.dataCollectionState = .off
        SharedSettings.save(settings)
        DispatchQueue.main.async { [weak self] in
            self?.currentState = .welcome
        }
        print("🔄 Reset to welcome. Both flags cleared.")
    }
}
