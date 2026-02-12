//
//  SettingsView.swift
//  Flick
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
                // Gestures Section
                Section {
                    SettingsRow(
                        icon: "arrow.left.arrow.right",
                        color: .orange,
                        title: "Reverse Flick directions"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { settings.isFlickDirectionReversed },
                            set: { newValue in
                                settings.isFlickDirectionReversed = newValue
                                saveSettingsImmediately()
                            }
                        ))
                        .labelsHidden()
                        .tint(.orange)
                    }
                    
                    SettingsRow(
                        icon: "hand.tap.fill",
                        color: .orange,
                        title: "Tap Watch to Play/Pause"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { settings.isTapEnabled },
                            set: { newValue in
                                settings.isTapEnabled = newValue
                                saveSettingsImmediately()
                            }
                        ))
                        .labelsHidden()
                        .tint(.orange)
                    }
                } header: {
                    Text("Gestures")
                }
                
                // Playback Method Section
                Section {
                    SettingsRow(
                        icon: "music.note",
                        color: .pink,
                        title: "Use Shortcuts"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { settings.useShortcutsForPlayback },
                            set: { newValue in
                                settings.useShortcutsForPlayback = newValue
                                saveSettingsImmediately()
                            }
                        ))
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
                                    .frame(width: 28, height: 28)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                
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
                
                // About
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
                
                // Debug Section (hidden in release)
                #if DEBUG
                Section {
                    Button(action: {
                        HapticManager.shared.playImpact()
                        appState.resetForDebug()
                        dismiss()
                    }) {
                        SettingsRow(
                            icon: "trash.fill",
                            color: .red,
                            title: "Clear all app data"
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
                            title: "Open test controls"
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
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                // Ensures settings are fresh every time the menu opens
                settings = SharedSettings.load()
                print("📱 Settings opened: tap=\(settings.isTapEnabled), reversed=\(settings.isFlickDirectionReversed)")
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShortcutsSetup) {
            ShortcutsSetupView()
        }
        .sheet(isPresented: $showTestControls) {
            TestView()
        }
    }
    
    // MARK: - Helpers
    
    private func saveSettingsImmediately() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        SharedSettings.save(settings)
        print("📱 Settings saved: tap=\(settings.isTapEnabled), reversed=\(settings.isFlickDirectionReversed)")
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
