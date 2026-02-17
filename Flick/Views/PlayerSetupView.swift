//
//  PlayerSetupView.swift
//  Flick
//
//  Choose playback method
//

import SwiftUI

struct PlayerSetupView: View {
    @EnvironmentObject var appState: AppStateManager
    
    @State private var selectedMethod: PlaybackMethod = .appleMusic
    @State private var showShortcutsSetup = false
    @State private var isAuthorizingSpotify = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Subtle ambient background light
            RadialGradient(
                gradient: Gradient(colors: [.orange.opacity(0.05), .clear]),
                center: .center,
                startRadius: 10,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Select Player")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 60)
                    
                    Text("Flick optimizes playback commands for your primary music service.")
                        .font(.body)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Selection Cards
                VStack(spacing: 24) {
                    // Apple Music
                    ServiceCard(
                        isSelected: selectedMethod == .appleMusic,
                        title: "Apple Music",
                        iconName: "Apple Music Icon",
                        isSystemIcon: false,
                        description: "Native Control",
                        color: .pink
                    ) {
                        select(.appleMusic)
                    }
                    
                    // Spotify
                    ServiceCard(
                        isSelected: selectedMethod == .spotify,
                        title: "Spotify",
                        iconName: "Spotify Icon",
                        isSystemIcon: false,
                        description: "App Remote",
                        color: .green
                    ) {
                        select(.spotify)
                    }
                    
                    #if DEBUG
                    // Shortcuts / Other
                    ServiceCard(
                        isSelected: selectedMethod == .shortcuts,
                        title: "Other Apps",
                        iconName: "Shortcuts Icon",
                        isSystemIcon: false,
                        description: "Via Shortcuts",
                        color: .indigo
                    ) {
                        select(.shortcuts)
                    }
                    #endif
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Info Text
                Text(infoText)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .frame(height: 40)
                    .animation(.easeInOut, value: selectedMethod)
                    .padding(.bottom, 10)
                
                // Continue Button
                Button(action: handleContinue) {
                    HStack {
                        if isAuthorizingSpotify {
                            ProgressView()
                                .tint(.black)
                                .padding(.trailing, 8)
                        }
                        Text(isAuthorizingSpotify ? "Connecting..." : "Continue")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.black)
                }
                .buttonStyle(VividGlassButtonStyle())
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
                .disabled(isAuthorizingSpotify)
            }
        }
        .fullScreenCover(isPresented: $showShortcutsSetup, onDismiss: {
            if UserDefaults.standard.bool(forKey: "shortcutsConfigured") {
                appState.completePlaybackChoice(method: .shortcuts)
            }
        }, content: {
            ShortcutsSetupView()
        })
    }
    
    // MARK: - Logic Helpers
    
    private func select(_ method: PlaybackMethod) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedMethod = method
        }
        HapticManager.shared.playImpact()
    }
    
    private var infoText: String {
        switch selectedMethod {
        case .appleMusic: return ""
        case .spotify: return "Spotify Premium requiered."
        case .shortcuts: return "You will be guided though Shortcuts setup next."
        }
    }
    
    private func handleContinue() {
        HapticManager.shared.playImpact()
        switch selectedMethod {
        case .appleMusic:
            appState.completePlaybackChoice(method: .appleMusic)
        case .spotify:
            isAuthorizingSpotify = true
            Task {
                await iOSMediaManager.shared.authorizeSpotify()
                await MainActor.run {
                    isAuthorizingSpotify = false
                    appState.completePlaybackChoice(method: .spotify)
                }
            }
        case .shortcuts:
            showShortcutsSetup = true
        }
    }
}

// MARK: - Refined Service Card (Backlight Glow)

struct ServiceCard: View {
    var isSelected: Bool
    var title: String
    var iconName: String
    var isSystemIcon: Bool
    var description: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color.opacity(0.1) : Color.white.opacity(0.05))
                        .frame(width: 50, height: 50)
                    
                    if isSystemIcon {
                        Image(systemName: iconName)
                            .font(.system(size: 24))
                            .foregroundStyle(isSelected ? color : .gray)
                    } else {
                        Image(iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            // Grayscale if not selected
                            .saturation(isSelected ? 1.0 : 0.0)
                            .opacity(isSelected ? 1.0 : 0.6)
                    }
                }
                
                // Text Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? color : .gray)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(color)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(18)
            .background {
                // 2. GLOW LOGIC: A distinct layer behind the card
                ZStack {
                    // Layer A: The "Backlight" Glow
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(color)
                            .blur(radius: 15)
                            .opacity(0.55)
                            .padding(-10)
                    }
                    
                    // Physical Card Body
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? color.opacity(0.35) : Color.white.opacity(0.05))
                }
            }
            .overlay(
                // Border
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.white.opacity(0.05), lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    PlayerSetupView()
        .environmentObject(AppStateManager())
}
