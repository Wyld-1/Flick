//
//  TutorialView.swift
//  Flick Watch App
//
//  Created by Liam Lefohn on 1/27/26.
//
// Interactive gesture tutorial

import SwiftUI

struct TutorialView: View {
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var motionManager = MotionManager()
    @State private var currentStep = 0
    @State private var gestureDetected = false
    @State private var showMediaIcon = false
    
    let tutorialSteps: [(gestureLeft: String, gestureRight: String, symbol: String, description: String, expectedGesture: GestureType)] = [
        (gestureLeft: "Flick wrist left", gestureRight: "Flick wrist right", symbol: "flick.ccw.2", description: "Next track", expectedGesture: .nextTrack),
        (gestureLeft: "Flick wrist right", gestureRight: "Flick wrist left", symbol: "flick.cw.2", description: "Previous track", expectedGesture: .previousTrack),
        (gestureLeft: "Hold upside-down", gestureRight: "Hold upside-down", symbol: "flip.ccw", description: "Play/pause", expectedGesture: .playPause)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                
                // Progress indicator
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            handleGestureDetection(tutorialSteps[currentStep].expectedGesture)
                        }
                    }) {
                        Text("\(currentStep + 1) / \(tutorialSteps.count)")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            // Magic transition
                            .contentTransition(.numericText(value: Double(currentStep)))
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .controlSize(.mini)
                    .fixedSize()
                    
                    Spacer()
                }
                .padding(.horizontal, 15) // Moves off left bezel
                .padding(.top, -38) // Moves toward top
                
                // Show media icon when gesture detected, otherwise show instruction icon
                ZStack {
                    if showMediaIcon {
                        Image(systemName: mediaIcon(for: tutorialSteps[currentStep].expectedGesture))
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.6)
                            .symbolEffect(.bounce, options: .repeat(1))
                    } else {
                        Image(tutorialSteps[currentStep].symbol)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.6)
                            .scaleEffect(x: appState.isLeftWrist ? 1 : -1, y: 1)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id("\(currentStep)-\(showMediaIcon)")
                
                Spacer(minLength: geometry.size.height * 0.12)
                
                // Instruction text
                VStack(spacing: 4) {
                    Text(appState.isLeftWrist ? tutorialSteps[currentStep].gestureLeft : tutorialSteps[currentStep].gestureRight)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(tutorialSteps[currentStep].description)
                        .foregroundStyle(.secondary)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentStep)
                .padding(.bottom, 12)
                .padding(.horizontal, 8)
            }
        }
        .onAppear {
            motionManager.startMonitoring()
            motionManager.isLeftWrist = appState.isLeftWrist
        }
        .onChange(of: motionManager.lastGesture) { oldValue, newValue in
            handleGestureDetection(newValue)
        }
    }
    
    private func handleGestureDetection(_ gesture: GestureType) {
        guard gesture == tutorialSteps[currentStep].expectedGesture else { return }
        
        gestureDetected.toggle()
        
        withAnimation(.spring(duration: 0.5)) {
            showMediaIcon = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            advanceStep()
        }
    }
    
    private func advanceStep() {
        if currentStep < tutorialSteps.count - 1 {
            withAnimation {
                showMediaIcon = false
                currentStep += 1
            }
        } else {
            // Final step - animate out before transitioning
            withAnimation(.spring(duration: 0.5)) {}
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    appState.completeTutorial()
                }
            }
        }
    }
    
    private func mediaIcon(for gesture: GestureType) -> String {
        switch gesture {
        case .nextTrack:
            return "forward.fill"
        case .previousTrack:
            return "backward.fill"
        case .playPause:
            return "playpause.fill"
        case .none:
            return "circle"
        }
    }
}

#Preview {
    TutorialView()
        .environmentObject(AppStateManager())
}
