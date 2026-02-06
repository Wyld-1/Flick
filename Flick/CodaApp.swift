//
//  CodaApp.swift
//  Coda iOS
//

import SwiftUI

@main
struct CodaApp: App {
    @State private var settings = SharedSettings.load()
    
    init() {
        _ = WatchConnectivityManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            if !settings.isTutorialCompleted {
                WelcomeView()
            } else {
                MainView()
            }
        }
    }
}
