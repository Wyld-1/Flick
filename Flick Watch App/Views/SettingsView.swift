//
//  HelpView.swift
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
                Toggle(isOn: $appState.isFlickDirectionReversed) {
                    HStack(spacing: 4) {
                        Text("Flip")
                        Image(systemName: "backward.fill")
                        Text("/")
                        Image(systemName: "forward.fill")
                    }
                }
                .tint(.orange)
                
                // Enable/disable tap for play/pause toggle
                Toggle(isOn: $appState.isTapEnabled) {
                    HStack(spacing: 4) {
                        Text("Tap screen to")
                        Image(systemName: "playpause.fill")
                    }
                }
                .tint(.orange)
                
                // Feedback link
                Link(destination: URL(string: "https://forms.gle/srpX8xf9EpCDjmC18")!) {
                    ZStack {
                        // Centered label
                        Text("Join the build")
                            .foregroundStyle(.purple)

                        // Left-aligned icon
                        HStack {
                            Image(systemName: "hammer.circle.fill")
                                .foregroundStyle(.purple)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Restart tutorial button
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    appState.resetToTutorial()
                }) {
                    ZStack {
                        // Centered label
                        Text("Replay tutorial")
                            .foregroundStyle(.orange)

                        // Left-aligned icon
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
                        // Centered label
                        Text("About")
                            .foregroundStyle(.secondary)

                        // Left-aligned icon
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
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStateManager())
}

