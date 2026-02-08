//
//  MainView.swift
//  Flick
//
//  Created by Liam Lefohn on 2/5/26.
//

import SwiftUI

struct MainView: View {
    @State private var showSettings = false
    @State private var showHelpSheet = false // 1. Added State
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
            
            // Bottom "Liquid Glass" Control Dock
            VStack {
                Spacer()
                
                // 2. Pass the help binding to the dock
                GlassControlDock(showSettings: $showSettings, showHelp: $showHelpSheet)
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        // 3. Added the Diagnostics Sheet
        .sheet(isPresented: $showHelpSheet) {
            WatchConnectionHelpView()
                .presentationDetents([.medium, .large])
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

// MARK: - Subviews

struct GlassControlDock: View {
    @Binding var showSettings: Bool
    @Binding var showHelp: Bool
    
    var isReachable: Bool {
        WatchConnectivityManager.shared.isReachable
    }
    
    var body: some View {
        HStack(spacing: 0) {
            
            // 5. Converted Left Side (Status) into a Button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                showHelp = true
            }) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(isReachable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                        .shadow(color: isReachable ? .green.opacity(0.8) : .red.opacity(0.8), radius: 6)
                    
                    Text(isReachable ? "WATCH ACTIVE" : "WATCH DISCONNECTED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize()
                }
                .padding(.leading, 24)
                .padding(.vertical, 16) // Added vertical padding to make touch target better
                .contentShape(Rectangle()) // Ensures the empty space in the stack is tappable
            }
            .padding(.trailing, 6)
            .buttonStyle(ScaleButtonStyle()) // Optional: Adds the press animation
            
            // Vertical divider
            Rectangle()
                .fill(.gray)
                .frame(width: 2, height: 24)
                .padding(.horizontal, 4)
            
            // Settings button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                showSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .contentShape(Rectangle()) // Makes the whole area tappable
            }
            .padding(.trailing, 6)
        }
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        // Added smooth animation for when the dock changes width
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isReachable)
    }
}

#Preview {
    MainView()
}
