//
//  SettingsView.swift
//  Flick
//
//  Created by Liam Lefohn on 2/5/26.
//

import SwiftUI

struct SettingsView: View {
    #if DEBUG
    @EnvironmentObject var appState: AppStateManager
    #endif
    
    @Environment(\.dismiss) var dismiss
    @State private var settings = SharedSettings.load()
    @State private var showShortcutsSetup = false
    @State private var showTestControls = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Gestures Section
                Section {
                    SettingsRow(
                        icon: "arrow.left.arrow.right",
                        color: .orange,
                        title: "Reverse Flick directions"
                    ) {
                        Toggle("", isOn: $settings.isFlickDirectionReversed)
                            .labelsHidden()
                            .tint(.orange)
                    }
                    
                    SettingsRow(
                        icon: "hand.tap.fill",
                        color: .orange,
                        title: "Tap Watch to Play/Pause"
                    ) {
                        Toggle("", isOn: $settings.isTapEnabled)
                            .labelsHidden()
                            .tint(.orange)
                    }
                } header: {
                    Text("Gestures")
                }
                
                // MARK: - Playback Method Section
                Section {
                    SettingsRow(
                        icon: "music.note",
                        color: .pink,
                        title: "Use Shortcuts"
                    ) {
                        Toggle("", isOn: $settings.useShortcutsForPlayback)
                            .labelsHidden()
                            .tint(.pink)
                    }
                    
                    // Conditional Configuration Rows
                    if settings.useShortcutsForPlayback {
                        Button(action: {
                            HapticManager.shared.playImpact()
                            showShortcutsSetup = true
                        }) {
                            SettingsRow(
                                icon: "gearshape.fill",
                                color: .pink,
                                title: "Configure Shortcuts"
                            ) {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.pink)
                            }
                        }
                        
                        Link(destination: URL(string: "shortcuts://")!) {
                            HStack(spacing: 12) {
                                Image("Shortcuts Icon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 28, height: 28) // Fixed: Matches SettingsRow size
                                    .clipShape(RoundedRectangle(cornerRadius: 6)) // Matches SettingsRow radius
                                
                                Text("Open Shortcuts App")
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.forward")
                                    .font(.caption)
                                    .foregroundStyle(.pink)
                            }
                        }
                    }
                } header: {
                    Text("Playback Source")
                } footer: {
                    if settings.useShortcutsForPlayback {
                        Text("Required for Spotify and others. Note: iPhone must be unlocked for shortcuts to run consistently.")
                    } else {
                        Text("Uses native Apple Music API. Works while locked, but supports Apple Music only.")
                    }
                }
                
                // MARK: - Community & About
                Section {
                    HStack {
                        SettingsRow(
                            icon: "number",
                            color: .purple,
                            title: "Version"
                        ) {
                            Text(AppConstants.appVersion)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    Link(destination: URL(string: "https://forms.gle/RSBVKFks8jatoQLS8")!) {
                        SettingsRow(
                            icon: "hammer.fill",
                            color: .purple,
                            title: "Build Flick with us"
                        ) {
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.purple)
                        }
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Created by Wyld-1 for the wild ones.")
                }
                
                // MARK: - Debug Section (Hidden in Release)
                #if DEBUG
                Section {
                    Button(action: {
                        HapticManager.shared.playImpact()
                        var newSettings = settings
                        newSettings.hasCompletedInitialSetup = false
                        newSettings.isTutorialCompleted = false
                        SharedSettings.save(newSettings)
                        appState.currentState = .welcome
                        dismiss()
                    }) {
                        SettingsRow(
                            icon: "arrow.counterclockwise",
                            color: .red,
                            title: "Reset to Welcome"
                        ) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    Button(action: {
                        HapticManager.shared.playImpact()
                        showTestControls = true
                    }) {
                        SettingsRow(
                            icon: "flask.fill",
                            color: .red,
                            title: "Open Test Controls"
                        ) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Debug Tools")
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticManager.shared.playImpact()
                        saveAndDismiss()
                    }
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
                }
            }
            .preferredColorScheme(.dark)
            // Global Change Listener
            .onChange(of: settings.isFlickDirectionReversed) { _, _ in autoSave() }
            .onChange(of: settings.isTapEnabled) { _, _ in autoSave() }
            .onChange(of: settings.useShortcutsForPlayback) { _, _ in autoSave() }
        }
        .sheet(isPresented: $showShortcutsSetup) {
            ShortcutsSetupView()
        }
        .sheet(isPresented: $showTestControls) {
            TestView()
        }
    }
    
    // MARK: - Helpers
    
    private func autoSave() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        SharedSettings.save(settings)
    }
    
    private func saveAndDismiss() {
        SharedSettings.save(settings)
        dismiss()
    }
}

// MARK: - Helper View Component
struct SettingsRow<Content: View>: View {
    let icon: String
    let color: Color
    let title: String
    let content: Content
    
    init(icon: String, color: Color, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.color = color
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Apple-style Icon Square
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(title)
                .foregroundStyle(.white)
            
            Spacer()
            
            content
        }
    }
}

#Preview {
    SettingsView()
}
