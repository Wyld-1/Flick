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
                // MARK: - Gestures Section
                Section {
                    SettingsRow(
                        icon: "switch.2",
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
                
                // MARK: - Playback Source Section
                Section {
                    // Custom Icon Row for Player Selection
                    SettingsRow(
                        icon: "speaker.wave.2.fill",
                        isSystemIcon: true,
                        color: currentColor,
                        title: "Playback Source"
                    ) {
                        Menu {
                            Picker("Source", selection: Binding(
                                get: { settings.playbackMethod },
                                set: { newValue in
                                    settings.playbackMethod = newValue
                                    saveSettingsImmediately()
                                    
                                    // Soft-connect check
                                    if newValue == .spotify && !spotifyAuthStatus{
                                        Task { await iOSMediaManager.shared.authorizeSpotify() }
                                    }
                                }
                            )) {
                                Label("Apple Music", image: "Apple Music Icon")
                                    .tag(PlaybackMethod.appleMusic)
                                
                                Label("Spotify", image: "Spotify Icon")
                                    .tag(PlaybackMethod.spotify)
                                
                                #if DEBUG
                                Label("Other", image: "Shortcuts Icon")
                                    .tag(PlaybackMethod.shortcuts)
                                #endif
                            }
                        } label: {
                            HStack {
                                Text(currentLabel)
                                    .foregroundStyle(.gray)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    
                    // --- Conditional Sub-Options ---
                    
                    // 1. SHORTCUTS SETUP
                    if settings.playbackMethod == .shortcuts {
                        Button(action: {
                            HapticManager.shared.playImpact()
                            showShortcutsSetup = true
                        }) {
                            SettingsRow(
                                icon: "gearshape.fill",
                                color: .purple,
                                title: "Configure Shortcuts"
                            ) {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.purple)
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
                                    .foregroundStyle(.purple)
                            }
                        }
                    }
                    
                    // 2. SPOTIFY STATUS & RE-AUTH
                    if settings.playbackMethod == .spotify {
                        // Authentication Status
                        SettingsRow(
                            icon: spotifyAuthStatus ? "shield.lefthalf.filled.badge.checkmark" : "shield.lefthalf.filled.slash",
                            color: spotifyAuthStatus ? .green : .red,
                            title: "Authenticated"
                        ) {
                            Text(spotifyAuthStatus ? "Yes" : "No")
                                .foregroundStyle(spotifyAuthStatus ? .green : .red)
                                .font(.subheadline)
                        }
                        
                        Button(action: {
                            HapticManager.shared.playImpact()
                            Task {
                                await MainActor.run {
                                    iOSMediaManager.shared.appRemote.authorizeAndPlayURI("")
                                }
                            }
                        }) {
                            SettingsRow(
                                icon: "key.shield.fill",
                                color: .green,
                                title: "Re-Authorize Spotify"
                            ) {
                                Image(systemName: "arrow.up.forward")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    
                } header: {
                    Text("Playback Source")
                } footer: {
                    switch settings.playbackMethod {
                    case .appleMusic:
                        Text("Apple Music subscription required.")
                    case .spotify:
                        Text("Spotify Premium required.")
                    case .shortcuts:
                        Text("Universal compatibility. Requires iPhone to be unlocked.")
                    }
                }
                
                // MARK: - About Section
                Section {
                    HStack {
                        SettingsRow(
                            icon: "number",
                            color: .indigo,
                            title: "Version"
                        ) {
                            Text(AppConstants.appVersion)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    Link(destination: URL(string: "https://forms.gle/RSBVKFks8jatoQLS8")!) {
                        SettingsRow(
                            icon: "hammer.fill",
                            color: .indigo,
                            title: "Build Flick with us"
                        ) {
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.indigo)
                        }
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Created by Wyld-1 for the wild ones.")
                }
                
                // MARK: - Debug Section
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
                settings = SharedSettings.load()
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
    }
    
    // Check Spotify auth status
    private var spotifyAuthStatus: Bool {
        iOSMediaManager.shared.hasValidToken || iOSMediaManager.shared.appRemote.isConnected
    }
    
    private var currentIconName: String {
        switch settings.playbackMethod {
        case .appleMusic: return "Apple Music Icon"
        case .spotify: return "Spotify Icon"
        case .shortcuts: return "Shortcuts Icon"
        }
    }
    
    private var currentColor: Color {
        switch settings.playbackMethod {
        case .appleMusic: return .pink
        case .spotify: return .green
        case .shortcuts: return .purple
        }
    }
    
    private var currentLabel: String {
        switch settings.playbackMethod {
        case .appleMusic: return "Apple Music"
        case .spotify: return "Spotify"
        case .shortcuts: return "Other"
        }
    }
}

// MARK: - Helper View Component
struct SettingsRow<Content: View>: View {
    let icon: String
    let isSystemIcon: Bool
    let color: Color
    let title: String
    let content: Content
    
    init(icon: String, isSystemIcon: Bool = true, color: Color, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.isSystemIcon = isSystemIcon
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
                
                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                } else {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.white)
                }
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
