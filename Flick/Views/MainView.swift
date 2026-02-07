//
//  MainView.swift
//  Coda
//
//  Created by Liam Lefohn on 2/5/26.
//

import SwiftUI

struct MainView: View {
    @State private var showSettings = false
    @State private var lastCommand: MediaCommand = .playPause
    @State private var commandTimestamp = Date()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Settings button
            VStack {
                HStack {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.glass)
                    .clipShape(Circle())
                    .controlSize(.extraLarge)
                    .padding(.leading, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                Spacer()
            }
            
            // Center circle
            VStack(spacing: 30) {
                ZStack {
                    Image(systemName: "circle")
                        .font(.system(size: 290))
                        .symbolEffect(.breathe.plain.wholeSymbol)
                        .foregroundStyle(.orange)
                    
                    Text("Flick")
                        .foregroundColor(Color(red: 96/255,
                                                    green: 0/255,
                                                    blue: 247/255))
                        .font(.system(size: 65))
                        .fontWeight(.black)
                }
            }
            
            // Watch Connection Status (Bottom)
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Circle()
                        .fill(WatchConnectivityManager.shared.isReachable ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text(WatchConnectivityManager.shared.isReachable ? "WATCH CONNECTED" : "WATCH DISCONNECTED")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .onAppear {
                    triggerHaptic()
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CommandReceived"))) { notification in
            if let command = notification.object as? MediaCommand {
                lastCommand = command
                commandTimestamp = Date()
            }
        }
    }
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func commandIcon(for command: MediaCommand) -> String {
        switch command {
        case .nextTrack:
            return "forward.fill"
        case .previousTrack:
            return "backward.fill"
        case .playPause:
            return "playpause.fill"
        }
    }
}

#Preview {
    MainView()
}
