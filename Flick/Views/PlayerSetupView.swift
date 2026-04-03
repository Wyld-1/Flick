//
//  PlayerSetupView.swift
//  Flick
//

import SwiftUI

struct PlayerSetupView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var selectedMethod: PlaybackMethod = .appleMusic
    @State private var showShortcutsSetup = false
    @State private var isAuthorizingSpotify = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Selection-dependent background
                if selectedMethod == .appleMusic {
                    RadialGradient(
                        gradient: Gradient(colors: [.pink.opacity(0.1), .clear]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 500
                    )
                    .ignoresSafeArea()
                }
                else if selectedMethod == .spotify {
                    RadialGradient(
                        gradient: Gradient(colors: [.green.opacity(0.1), .clear]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 500
                    )
                    .ignoresSafeArea()
                }
                else {
                    RadialGradient(
                        gradient: Gradient(colors: [.indigo.opacity(0.1), .clear]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 500
                    )
                    .ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Text("Select Player")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 40)
                        
                        Text("Flick optimizes playback commands for your primary music service.")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        FlickServiceCard(
                            isSelected: selectedMethod == .appleMusic,
                            title: "Apple Music",
                            description: "",
                            iconName: "Apple Music Icon",
                            isSystemIcon: false,
                            color: .pink
                        ) { select(.appleMusic) }
                        
                        FlickServiceCard(
                            isSelected: selectedMethod == .spotify,
                            title: "Spotify",
                            description: "",
                            iconName: "Spotify Icon",
                            isSystemIcon: false,
                            color: .green
                        ) { select(.spotify) }
                        
                        #if DEBUG
                        FlickServiceCard(
                            isSelected: selectedMethod == .shortcuts,
                            title: "Other Apps",
                            description: "Via Shortcuts",
                            iconName: "Shortcuts Icon",
                            isSystemIcon: false,
                            color: .indigo
                        ) { select(.shortcuts) }
                        #endif
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    Text(infoText)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .frame(height: 50)
                    
                    Button(action: handleContinue) {
                        HStack {
                            if isAuthorizingSpotify {
                                ProgressView().tint(.black).padding(.trailing, 8)
                            }
                            Text(isAuthorizingSpotify ? "Connecting..." : "Continue")
                                .frame(height: 45)
                        }
                        .font(.headline).bold()
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.black)
                    }
                    .padding(.horizontal, 30)
                    .tint(.orange)
                    .flickProminentButton()
                    .disabled(isAuthorizingSpotify)
                }
            }
        }
        .fullScreenCover(isPresented: $showShortcutsSetup, onDismiss: {
            if UserDefaults.standard.bool(forKey: "shortcutsConfigured") {
                appState.completePlaybackChoice(method: .shortcuts)
            }
        }) {
            ShortcutsSetupView()
        }
    }
    
    private func select(_ method: PlaybackMethod) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedMethod = method
        }
        HapticManager.shared.playImpact()
    }
    
    private var infoText: String {
        switch selectedMethod {
        case .appleMusic: return "Apple Muisc subscription required."
        case .spotify: return "Spotify Premium required."
        case .shortcuts: return "You will be guided through Shortcuts setup next."
        }
    }
    
    private func handleContinue() {
        HapticManager.shared.playImpact()
        var settings = SharedSettings.load()
        switch selectedMethod {
        case .appleMusic:
            settings.hasCompletedInitialSetup = true
            SharedSettings.save(settings)
            appState.completePlaybackChoice(method: .appleMusic)
        case .spotify:
            isAuthorizingSpotify = true
            Task {
                await iOSMediaManager.shared.authorizeSpotify()
                await MainActor.run {
                    isAuthorizingSpotify = false
                    settings.hasCompletedInitialSetup = true
                    SharedSettings.save(settings)
                    appState.completePlaybackChoice(method: .spotify)
                }
            }
            // Note: auth is also triggered automatically on the first gesture
            // if the user skips it here. Re-auth is available in Settings.
        case .shortcuts:
            showShortcutsSetup = true
        }
    }
}

#Preview {
    PlayerSetupView()
        .environmentObject(AppStateManager())
}
