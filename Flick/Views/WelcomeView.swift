//
//  WelcomeView.swift
//  Coda
//
//  Created by Liam Lefohn on 2/5/26.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            
            // Play icon and welcome text
            VStack(spacing: 40) {
                Spacer()
                
                Image(systemName: "play")
                    .font(.system(size: 215))
                    .foregroundStyle(.orange)
                    .symbolEffect(.breathe.plain.wholeSymbol, options: .repeat(.continuous))
                
                    // Unused setup to make play icon clickable
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("Play tapped!")
                    }
            
                Spacer()
                
                Text("Welcome to Coda")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(.bottom, 130) // Matches sheet height to prevent overlap
            
            // Instruction card
            VStack {
                Spacer() // Pushes the content to the bottom of the screen
                
                VStack(spacing: 20) {
                    Capsule()
                        .frame(width: 40, height: 5)
                        .foregroundStyle(.secondary)
                        .padding(.top, 10)
                    
                    HStack(spacing: 20) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 70))
                            .foregroundStyle(.orange)
                        
                        Text("Complete the tutorial on Apple Watch")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(.ultraThinMaterial)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 44, // Modern iPhone screen radius
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 44
                    )
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    WelcomeView()
}
