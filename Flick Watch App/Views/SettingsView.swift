//
//  SettingsView.swift (Watch)
//  Flick
//
//  Created by Liam Lefohn on 1/30/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var showCredits = false
    
    var body: some View {
        List {
            Section {
                // Reverse flick directions
                Toggle(isOn: Binding(
                    get: { appState.isFlickDirectionReversed },
                    set: { newValue in
                        appState.isFlickDirectionReversed = newValue
                        appState.saveSettings()
                        WKInterfaceDevice.current().play(.click)
                    }
                )) {
                    HStack(spacing: 4) {
                        Text("Flip")
                        Image(systemName: "backward.fill")
                        Text("/")
                        Image(systemName: "forward.fill")
                    }
                }
                .tint(.orange)
                
                // Enable/disable tap for play/pause toggle
                Toggle(isOn: Binding(
                    get: { appState.isTapEnabled },
                    set: { newValue in
                        appState.isTapEnabled = newValue
                        appState.saveSettings()
                        WKInterfaceDevice.current().play(.click)
                    }
                )) {
                    HStack(spacing: 4) {
                        Text("Tap screen to")
                        Image(systemName: "playpause.fill")
                    }
                }
                .tint(.orange)
                
                // Restart tutorial button
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    appState.resetToTutorial()
                }) {
                    ZStack {
                        Text("Replay tutorial")
                            .foregroundStyle(.orange)
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Credits button
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    showCredits = true
                }) {
                    ZStack {
                        Text("About")
                            .foregroundStyle(.secondary)
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
            .listStyle(.plain)
            
            #if DEBUG
            Section {
                // DEBUG: Clear all data
                
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    clearAllData()
                }) {
                    ZStack {
                        Text("Clear all data")
                            .foregroundStyle(.red)
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .listStyle(.plain)
            #endif
            
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
        .onAppear {
            appState.loadSettings()
        }
    }
    
    // MARK: - Debug Helper
    #if DEBUG
    private func clearAllData() {
        // 1. Clear local UserDefaults
        UserDefaults.standard.removeObject(forKey: "hasCompletedWelcome")
        
        // 2. Clear shared settings
        var settings = SharedSettings.load()
        settings.isTutorialCompleted = false
        settings.hasCompletedInitialSetup = false
        settings.isTapEnabled = false
        settings.isFlickDirectionReversed = false
        settings.useShortcutsForPlayback = false
        SharedSettings.save(settings)
        
        // 3. Reset app state
        appState.resetToWelcome()
        
        print("⌚️ 🗑️ All data cleared - reset to welcome")
    }
    #endif
}

#Preview {
    SettingsView()
        .environmentObject(AppStateManager())
}
