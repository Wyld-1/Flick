//
//  AppStateManager.swift
//  Flick
//
//  Created by Liam Lefohn on 1/27/26.
//
// Tracks which screen to show

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
    @Published var isTapEnabled: Bool {
            didSet {
                UserDefaults.standard.set(isTapEnabled, forKey: "isTapEnabled")
            }
        }
    @Published var isFlickDirectionReversed: Bool {
        didSet {
            UserDefaults.standard.set(isFlickDirectionReversed, forKey: "isFlickDirectionReversed")
        }
    }
    
    init() {
        // Check wrist orientation
        let wristLocation = WKInterfaceDevice.current().wristLocation
        self.isLeftWrist = (wristLocation == .left)
        
        // Load saved settings
        self.isTapEnabled = UserDefaults.standard.bool(forKey: "isTapEnabled")
        self.isFlickDirectionReversed = UserDefaults.standard.bool(forKey: "isFlickDirectionReversed")
        
        // Check if first launch
        let hasCompletedWelcome = UserDefaults.standard.bool(forKey: "hasCompletedWelcome")
        self.currentState = hasCompletedWelcome ? .main : .welcome
    }
    
    func completeWelcome() {
        UserDefaults.standard.set(true, forKey: "hasCompletedWelcome")
        currentState = .tutorial
    }
    
    func completeTutorial() {
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
