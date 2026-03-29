//
//  WelcomeView.swift
//  Flick
//
//  Created by Liam Lefohn on 2/6/26.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppStateManager
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Subtle ambient glow
            RadialGradient(
                gradient: Gradient(colors: [.orange.opacity(0.1), .clear]),
                center: .center,
                startRadius: 10,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Play icon
                Image(systemName: "play")
                    .font(.system(size: 215))
                    .foregroundStyle(.orange)
                    .symbolEffect(.breathe.plain.wholeSymbol, options: .repeat(.continuous))
                    .shadow(color: .orange.opacity(0.3), radius: 40)
                
                Spacer()
                
                // Text content
                VStack(spacing: 12) {
                    Text("Welcome to Flick")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Playback just got convenient")
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Continue button
                Button(action: {
                    HapticManager.shared.playImpact()
                    appState.completeWelcome()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 30)
                .tint(.orange)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppStateManager())
}
