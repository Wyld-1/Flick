//
//  ReusableGraphics.swift
//  Flick
//
//  Consolidated graphics, styles, and haptic engine
//

import SwiftUI
import UIKit // Required for UIImpactFeedbackGenerator
import WatchConnectivity

// MARK: - Haptic Manager (The Fix for Lag)
class HapticManager {
    static let shared = HapticManager()
    
    // key: Keep these as properties so the engine stays "warm"
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    private init() {}
    
    /// Call this when the app launches to wake up the Taptic Engine
    func prepare() {
        mediumImpact.prepare()
        notification.prepare()
        selection.prepare()
    }
    
    func playImpact() {
        mediumImpact.impactOccurred()
    }
    
    func playSuccess() {
        notification.notificationOccurred(.success)
    }
    
    func playWarning() {
        notification.notificationOccurred(.warning)
    }
    
    func playSelection() {
        selection.selectionChanged()
    }
}

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct VividGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(Color.orange)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.5), location: 0),
                                .init(color: .white.opacity(0.0), location: 0.5),
                                .init(color: .white.opacity(0.2), location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Glass Status Dock

struct GlassStatusDock: View {
    @Binding var showHelp: Bool
    // Local state to track changes for notification haptics
    @State private var previousReachability = false
    
    var isReachable: Bool {
        WatchConnectivityManager.shared.isReachable
    }
    
    var body: some View {
        Button(action: {
            // 🚀 FAST: Uses the pre-warmed singleton
            HapticManager.shared.playImpact()
            showHelp = true
        }) {
            HStack(spacing: 10) {
                Circle()
                    .fill(isReachable ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .shadow(color: isReachable ? .green.opacity(0.8) : .red.opacity(0.8), radius: 6)
                
                Text(isReachable ? "WATCH CONNECTED" : "WATCH DISCONNECTED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize()
                
                // Vertical divider
                Rectangle()
                    .fill(.gray.opacity(0.5))
                    .frame(width: 1, height: 16)
                    .padding(.horizontal, 4)
                
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.4), location: 0),
                                .init(color: .white.opacity(0.0), location: 0.5),
                                .init(color: .white.opacity(0.2), location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
        .onChange(of: isReachable) { old, new in
            if new && !previousReachability {
                // Connected
                HapticManager.shared.playSuccess()
            } else if !new && previousReachability {
                // Disconnected
                HapticManager.shared.playWarning()
            }
            previousReachability = new
        }
        .onAppear {
            previousReachability = isReachable
        }
    }
}
