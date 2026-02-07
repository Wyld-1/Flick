//  FlickApp.swift (iOS)
//  Replace @State with @StateObject and observe changes

import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var settings: AppSettings
    
    init() {
        self.settings = SharedSettings.load()
        
        // Listen for settings updates
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.settings = SharedSettings.load()
        }
    }
}

@main
struct FLickApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        _ = WatchConnectivityManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            /*
            if !appState.settings.isTutorialCompleted {
                WelcomeView()
            } else {
                MainView()
             }
             */
            
            MainView()
        }
    }
}
