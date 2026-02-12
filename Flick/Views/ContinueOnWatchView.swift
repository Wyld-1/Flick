//
//  ContinueOnWatchView.swift
//  Flick
//
//  Wait for Watch tutorial
//

import SwiftUI
import WatchConnectivity

struct ContinueOnWatchView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var isAnimating = false
    @State private var showHelpSheet = false
    
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
            
            // MARK: - Debug buttons
            #if DEBUG
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.shared.playImpact()
                        appState.resetForDebug()
                    }) {
                        Text("RESTART")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    Spacer()
                    Spacer()
                    
                    Button(action: {
                        HapticManager.shared.playImpact()
                        var settings = SharedSettings.load()
                        settings.isTutorialCompleted = true
                        SharedSettings.save(settings)
                        appState.goToMain()
                    }) {
                        Text("SKIP TO MAIN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                    Spacer()
                }
                .padding(.top, 60)
                Spacer()
            }
            .zIndex(10)
            #endif
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    // Ripple
                    ForEach(0..<1) { index in
                        Circle()
                            .stroke(.orange, lineWidth: 6)
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 2.3 : 1.3)
                            .opacity(isAnimating ? 0 : 0.3)
                            .blur(radius: isAnimating ? 8 : 2) // Blur increases as it expands
                            .animation(
                                .easeOut(duration: 2.3)
                                .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                    
                    // Central icon
                    ZStack {
                        Circle()
                            .fill(.orange.opacity(0.3))
                            .frame(width: 140, height: 140)
                            .shadow(color: .orange.opacity(0.2), radius: 20)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Image(systemName: "applewatch")
                            .font(.system(size: 70))
                            .foregroundStyle(.orange)
                    }
                }
                .frame(height: 350)
                
                // Text instructions
                VStack(spacing: 20) {
                    Text("Continue on Apple Watch")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                    
                    Text("Complete the tutorial to finish setup.")
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                // Control Dock
                GlassStatusDock(showHelp: $showHelpSheet)
                    .padding(.bottom, 6)
            }
        }
        .sheet(isPresented: $showHelpSheet) {
            ConnectionHelpView()
                .presentationDetents([.height(230), .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ContinueOnWatchView()
        .environmentObject(AppStateManager())
}
