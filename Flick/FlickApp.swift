//
//  FlickApp.swift
//  Flick iOS
//

import SwiftUI

@main
struct FlickApp: App {
    @StateObject private var appState = AppStateManager()
    
    init() {
        _ = WatchConnectivityManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState.currentState {
                case .welcome:
                    WelcomeView()
                        .transition(.opacity)
                    
                case .playbackChoice:
                    PlayerSetupView()
                        .transition(.move(edge: .trailing))
                    
                case .waitingForWatch:
                    ContinueOnWatchView()
                        .transition(.move(edge: .trailing))
                    
                case .main:
                    MainView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: appState.currentState)
            .environmentObject(appState)
        }
    }
}
