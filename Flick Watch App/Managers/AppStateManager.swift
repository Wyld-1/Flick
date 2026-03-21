//
//  AppStateManager.swift
//  Flick (Watch)
//

import SwiftUI
import Combine

enum AppState {
    case welcome
    case tutorial
    case main
}

class AppStateManager: ObservableObject {
    @Published var currentState: AppState
    @Published var isLeftWrist: Bool = true
    @Published var isTapEnabled: Bool
    @Published var isFlickDirectionReversed: Bool
    @Published var playbackMethod: PlaybackMethod
    
    private var mSettingsObserver: NSObjectProtocol?
    
    init() {
        let wristLocation = WKInterfaceDevice.current().wristLocation
        self.isLeftWrist = (wristLocation == .left)
        
        // Load from shared storage
        let settings = SharedSettings.load()
        self.isTapEnabled = settings.isTapEnabled
        self.isFlickDirectionReversed = settings.isFlickDirectionReversed
        self.playbackMethod = settings.playbackMethod
        
        let hasCompletedWelcome = UserDefaults.standard.bool(forKey: "hasCompletedWelcome")
        self.currentState = hasCompletedWelcome ? .main : .welcome
        
        mSettingsObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadSettings()
        }
    }
    
    deinit {
        if let observer = mSettingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func saveSettings() {
        var settings = SharedSettings.load()
        settings.isTapEnabled = self.isTapEnabled
        settings.isFlickDirectionReversed = self.isFlickDirectionReversed
        settings.playbackMethod = self.playbackMethod
        SharedSettings.save(settings)
        
        print("⌚️ Settings saved to SharedSettings")
    }
    
    func loadSettings() {
        let settings = SharedSettings.load()
        self.isTapEnabled = settings.isTapEnabled
        self.isFlickDirectionReversed = settings.isFlickDirectionReversed
        self.playbackMethod = settings.playbackMethod
        
        print("⌚️ Settings loaded from SharedSettings")
    }
    
    func completeWelcome() {
        UserDefaults.standard.set(true, forKey: "hasCompletedWelcome")
        currentState = .tutorial
    }
    
    func completeTutorial() {
        var settings = SharedSettings.load()
        settings.isTutorialCompleted = true
        SharedSettings.save(settings)
        currentState = .main
    }
     
    func resetToTutorial() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedWelcome")
        currentState = .tutorial
    }
    
    func resetToWelcome() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedWelcome")
        currentState = .welcome
    }
    
    func goToMain() {
        currentState = .main
    }
}
