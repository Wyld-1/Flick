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
                        .symbolEffect(.breathe.plain.wholeSymbol)
                        .foregroundStyle(.orange.opacity(0.8))
                        .shadow(
                            color: .orange.opacity(0.3),
                            radius: isAnimatingShadow ? 50 : 20
                        )
                    
                    Text("Flick")
                        .foregroundColor(Color(red: 96/255,
                                             green: 0/255,
                                             blue: 247/255))
                        .font(.system(size: 65))
                        .fontWeight(.black)
                }
            }
            .offset(y: -20)
            
            VStack {
                Spacer()
                
                HStack(spacing: 16) {
                    Spacer()
                    
                    // Watch status dock
                    GlassStatusDock(showHelp: $showHelpSheet)
                    
                    // Settings button
                    Button(action: {
                        HapticManager.shared.playImpact()
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 64, height: 64)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            stops: [
                                                .init(color: .white.opacity(0.4), location: 0),
                                                .init(color: .white.opacity(0.1), location: 0.5),
                                                .init(color: .white.opacity(0.05), location: 1)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 0) // Adjusts vertical position
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
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
