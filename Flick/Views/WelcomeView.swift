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
                    
                    Text("Buttons just had a bad day.")
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Bright orange Continue button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    withAnimation(.spring()) {
                        appState.completeWelcome()
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.black)
                }
                .buttonStyle(VividGlassButtonStyle()) // Uses shared style
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppStateManager())
}
