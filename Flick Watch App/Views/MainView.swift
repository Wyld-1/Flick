//
//  MainView.swift
//  Flick
//
//  Created by Liam Lefohn on 1/27/26.
//
// Main app screen (live app)

import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var motionManager = MotionManager()
    @ObservedObject private var dataCollector = DataCollectionManager.shared
    @State private var lastGesture: GestureType = .none
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var showSettings = false
    private let GESTURE_DETECTED_ICON_TIME = 2
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Tappable background layer
                ZStack {
                    // Background breathing circle - color based on recording state
                    Image(systemName: "circle")
                        .font(.system(size: geometry.size.width * 0.85))
                        .symbolEffect(.breathe.plain.wholeSymbol, isActive: !isLuminanceReduced)
                        .foregroundStyle(ringColor)
                    
                    // Center content - varies by state
                    ZStack {
                        // Recording/Syncing states
                        if dataCollector.currentState != .off {
                            Text(centerText)
                                .foregroundColor(.red)
                                .font(.system(size: geometry.size.width * 0.1))
                                .fontWeight(.black)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            // Normal mode - Gesture icon or Flick text
                            if lastGesture != .none {
                                Image(systemName: gestureIcon(for: lastGesture))
                                    .font(.system(size: geometry.size.width * 0.25))
                                    .foregroundStyle(AppConstants.flickPurple)
                                    .fontWeight(.black)
                                    .symbolEffect(.bounce, value: lastGesture)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Text("Flick")
                                    .foregroundColor(AppConstants.flickPurple)
                                    .font(.system(size: geometry.size.width * 0.2))
                                    .fontWeight(.black)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: lastGesture)
                    .animation(.easeInOut(duration: 0.3), value: dataCollector.currentState)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    if appState.isTapEnabled {
                        WatchConnectivityManager.shared.sendMediaCommand(.playPause)
                        WKInterfaceDevice.current().play(.click)
                        
                        // Show icon temporarily
                        withAnimation {
                            lastGesture = .playPause
                        }
                        
                        // Hide after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(GESTURE_DETECTED_ICON_TIME)) {
                            withAnimation {
                                lastGesture = .none
                            }
                        }
                    }
                }
                
                // Settings button on top
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
            // Update local state when gesture detected
            withAnimation {
                lastGesture = newValue
            }
            
            // If gesture was detected (not .none), auto-hide after a delay
            if newValue != .none {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(GESTURE_DETECTED_ICON_TIME)) {
                    withAnimation {
                        lastGesture = .none
                    }
                }
            }
        }
    }
    
    // Ring color based on recording state
    private var ringColor: Color {
        switch dataCollector.currentState {
        case .off:
            return .orange
        case .recording, .syncing:
            return .red
        }
    }
    
    // Center text based on recording state
    private var centerText: String {
        switch dataCollector.currentState {
        case .off:
            return "Flick"
        case .recording:
            return "RECORDING"
        case .syncing:
            return "SYNCING"
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
