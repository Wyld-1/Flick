//
//  FlickApp.swift
//  Flick Watch App
//
//  Created by Liam Lefohn on 1/27/26.
//
// Entry point, routes to correct view

import SwiftUI

@main
struct Flick_Watch_AppApp: App {
    @StateObject private var appState = AppStateManager()
        
    init() {
        // Initialize Watch Connectivity
        _ = WatchConnectivityManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState.currentState {
                case .welcome:
                    WelcomeView()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                case .tutorial:
                    TutorialView()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                case .main:
                    MainView()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.6), value: appState.currentState)
            .environmentObject(appState)
        }
    }
}
