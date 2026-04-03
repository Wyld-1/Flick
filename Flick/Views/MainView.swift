//
//  MainView.swift
//  Flick
//
//  Created by Liam Lefohn on 2/5/26.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var showSettings = false
    @State private var showDataCollection = false
    @State private var showHelpSheet = false
    @State private var lastCommand: MediaCommand = .playPause
    @State private var commandTimestamp = Date()
    @State private var isAnimatingShadow = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [.orange.opacity(0.1), .clear]),
                center: .center,
                startRadius: 10,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Center Brand Element
            VStack(spacing: 30) {
                ZStack {
                    Image(systemName: "circle")
                        .font(.system(size: 290))
                        .foregroundStyle(.orange.opacity(0.8))
                        .shadow(
                            color: .orange.opacity(0.3),
                            radius: isAnimatingShadow ? 50 : 20
                        )
                    
                    Text("Flick")
                        .foregroundColor(AppConstants.flickPurple)
                        .font(.system(size: 65))
                        .fontWeight(.black)
                }
            }
            .offset(y: -20)
            
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    GlassStatusDock(showHelp: $showHelpSheet)
                    
                    HStack(spacing: 0) {
                        // Training Data Button
                        Button(action: {
                            HapticManager.shared.playImpact()
                            showDataCollection = true
                        }) {
                            Image(systemName: "cpu.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(width: 48, height: 48)
                        }
                        
                        // Vertical Divider
                        Rectangle()
                            .fill(.white.opacity(0.18))
                            .frame(width: 1, height: 16)
                            .padding(.horizontal, 4)
                        
                        // Settings Button
                        Button(action: {
                            HapticManager.shared.playImpact()
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(width: 48, height: 48)
                        }
                    }
                    .clipShape(Capsule())
                    .flickGlass(in: Capsule())
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        
        // Training Data sheet
        .sheet(isPresented: $showDataCollection) {
            NavigationStack {
                DataCollectionView()
            }
        }
        
        // Diagnostics sheet
        .sheet(isPresented: $showHelpSheet) {
            ConnectionHelpView()
                .presentationDetents([.height(230), .large])
                .presentationDragIndicator(.visible)
        }
        
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CommandReceived"))) { notification in
            if let command = notification.object as? MediaCommand {
                lastCommand = command
                commandTimestamp = Date()
            }
        }
        
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimatingShadow = true
            }
        }
    }
}

#Preview {
    MainView()
}
