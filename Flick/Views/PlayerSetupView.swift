//
//  PlayerSetupView.swift
//  Flick
//
//  Choose playback method
//

import SwiftUI

struct PlayerSetupView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var useShortcuts = false // false = Apple Music, true = Other
    @State private var showShortcutsSetup = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [.orange.opacity(0.1), .clear]),
                center: .center,
                startRadius: 10,
                endRadius: 400
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
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Selection Buttons
                HStack(spacing: 20) {
                    // Apple Music (Native)
                    ServiceCard(
                        isSelected: !useShortcuts,
                        title: "Apple Music",
                        iconName: "Apple Music Icon",
                        description: "Native Control",
                        color: .pink
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            useShortcuts = false
                        }
                        appState.triggerHaptic()
                    }
                    
                    // Spotify / Other (Shortcuts)
                    ServiceCard(
                        isSelected: useShortcuts,
                        title: "Spotify / Other",
                        iconName: "Spotify Icon",
                        description: "Via Shortcuts",
                        color: .green
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            useShortcuts = true
                        }
                        appState.triggerHaptic()
                    }
                }
                .frame(height: 220)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Info Text
                Text(useShortcuts ? "Flick will help you set up Shortcuts in the next step." : "")
                    .font(.body)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                    .frame(height: 40)
                    .animation(.easeInOut, value: useShortcuts)
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    appState.triggerHaptic()
                    
                    if useShortcuts {
                        // Show shortcuts setup as fullScreenCover
                        showShortcutsSetup = true
                    } else {
                        // Finish immediately for Apple Music
                        appState.completePlaybackChoice(useShortcuts: false)
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.black)
                }
                .buttonStyle(VividGlassButtonStyle())
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showShortcutsSetup) {
            // onDismiss callback - runs when sheet closes
            if UserDefaults.standard.bool(forKey: "shortcutsConfigured") {
                appState.completePlaybackChoice(useShortcuts: true)
            }
        } content: {
            ShortcutsSetupView()
        }
    }
}

// MARK: - Subviews

struct ServiceCard: View {
    var isSelected: Bool
    var title: String
    var iconName: String
    var description: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Card Background
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                isSelected ? color : .white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 20)
                
                VStack(spacing: 20) {
                    // Icon Circle
                    ZStack {
                        Circle()
                            .fill(isSelected ? color.opacity(0.2) : Color.white.opacity(0.05))
                            .frame(width: 80, height: 80)
                        
                        // Using your custom Assets
                        Image(iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    }
                    
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(isSelected ? .white : .gray)
                        
                        Text(description)
                            .font(.caption2)
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : .gray.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                }
                .padding()
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    PlayerSetupView()
        .environmentObject(AppStateManager())
}
