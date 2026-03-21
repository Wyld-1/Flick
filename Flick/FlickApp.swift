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
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    
                case .playbackChoice:
                    PlayerSetupView()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    
                case .waitingForWatch:
                    ContinueOnWatchView()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    
                case .main:
                    MainView()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: appState.currentState)
            .environmentObject(appState)
            // Handle Spotify OAuth callback
            .onOpenURL { url in
                if url.scheme == "flick" {
                    iOSMediaManager.shared.handleSpotifyURL(url)
                } else {
                    print("⚠️ Unknown URL scheme: \(url.scheme ?? "nil")")
                }
            }
        }
    }
}
