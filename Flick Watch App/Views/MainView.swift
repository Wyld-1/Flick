//
//  MainView.swift
//  Flick
//
//  Created by Liam Lefohn on 1/27/26.
//
// Main app screen (live app)

import SwiftUI

struct MainView: View {
    @StateObject private var motionManager = MotionManager()
    @State private var lastGesture: GestureType = .none
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var showSettings = false
    @EnvironmentObject var appState: AppStateManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Tappable background layer
                ZStack {
                    // Background breathing circle
                    Image(systemName: "circle")
                        .font(.system(size: geometry.size.width * 0.85))
                        .symbolEffect(.breathe.plain.wholeSymbol, isActive: !isLuminanceReduced)
                        .foregroundStyle(.orange)
                    
                    // Gesture icon (replaces "Flick" text)
                    if lastGesture != .none {
                        Image(systemName: gestureIcon(for: lastGesture))
                            .font(.system(size: geometry.size.width * 0.25))
                            .foregroundStyle(.blue)
                            .fontWeight(.black)
                            .symbolEffect(.bounce, value: lastGesture)
                    } else {
                        Text("Flick")
                            .foregroundColor(Color(red: 96/255,
                                                        green: 0/255,
                                                        blue: 247/255))
                            .font(.system(size: geometry.size.width * 0.2))
                            .fontWeight(.black)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    if appState.isTapEnabled {
                        WKInterfaceDevice.current().play(.click)
                        mediaManager.handleGesture(.playPause)
                        withAnimation {
                            lastGesture = .playPause
                        }
                    }
                }
                
                // Button layer on top, and unaffected by screen tap
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.small)
                .clipShape(.circle)
                .position(
                    x: geometry.size.width * 0.16,
                    y: geometry.size.height * -0.115
                )
                .opacity(isLuminanceReduced ? 0.6 : 1)
                
                // Ensures button receives taps first
                .allowsHitTesting(true)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            motionManager.startMonitoring()
            motionManager.isLeftWrist = appState.isLeftWrist
            motionManager.appState = appState
        }
        .onChange(of: motionManager.lastGesture) { oldValue, newValue in
            withAnimation {
                lastGesture = newValue
                mediaManager.handleGesture(newValue)
            }
        }
    }
    
    // Map gesture types to SF Symbols
    func gestureIcon(for gesture: GestureType) -> String {
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
    MainView()
        .environmentObject(AppStateManager())
}
