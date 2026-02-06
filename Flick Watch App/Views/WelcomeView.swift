//
//  WelcomeView.swift
//  Flick Watch App
//
//  Created by Liam Lefohn on 1/27/26.
//
// First-time welcome screen

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var tempMotion = MotionManager()
    @State private var triggerPulse = false
    @State private var isTextVisible = false
    @State private var isRequesting = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Image(systemName: "play")
                    .font(.system(size: geometry.size.width * 0.45))
                    .symbolEffect(.pulse, value: triggerPulse)
                    .symbolEffect(.breathe.plain.wholeSymbol, options: .repeat(.continuous))
                    .imageScale(.large)
                    .foregroundStyle(.orange)
                    .onTapGesture {
                        handleTap()
                    }
                
                Spacer()
                    .frame(height: geometry.size.height * 0.15)
                
                Text("Playback just got convenient")
                    .foregroundStyle(.secondary)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    // Prevents horizontal compression and allows vertical expansion
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 5)
                    
                    // Fade in animation
                    .opacity(isTextVisible ? 1 : 0) // Animate opacity from 0 to 1
                    .animation(.easeInOut(duration: 2).delay(0), value: isTextVisible)
                    .onAppear {
                        isTextVisible = true // Trigger the animation when the view appears
                    }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
    
    private func handleTap() {
        guard !isRequesting else { return }
        isRequesting = true
        triggerPulse.toggle()
        WKInterfaceDevice.current().play(.click)
        
        // Request HealthKit access. Once done, continue
        tempMotion.requestHealthKitAuthorization { success in
            WKInterfaceDevice.current().play(.click)
            withAnimation(.spring(duration: 0.5)) {}
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    appState.completeWelcome()
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppStateManager())
}
