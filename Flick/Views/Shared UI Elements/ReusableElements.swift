//
//  ReusableElements.swift
//  Flick
//
//  Consolidated graphics, styles, and haptic engine
//

import SwiftUI
import UIKit // Required for UIImpactFeedbackGenerator
import WatchConnectivity

// MARK: - Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    private init() {}
    
    // Call this when the app launches to wake up the Haptic Engine
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
    var color: Color = .orange
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(color) // Use dynamic color
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
    
    @ObservedObject private var connectivity = WatchConnectivityManager.shared
    
    // Check proper connection status
    private var isConnected: Bool {
        WCSession.default.isPaired && WCSession.default.isWatchAppInstalled
    }
    
    // Local state to track changes for notification haptics
    @State private var previousConnection = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playImpact()
            showHelp = true
        }) {
            HStack(spacing: 10) {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .shadow(color: isConnected ? .green.opacity(0.8) : .red.opacity(0.8), radius: 6)
                
                Text(isConnected ? "WATCH CONNECTED" : "WATCH DISCONNECTED")
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 8, height: 48)
            }
            .padding(.horizontal, 20)
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
        .onChange(of: isConnected) { old, new in
            if new && !previousConnection {
                HapticManager.shared.playSuccess()
            } else if !new && previousConnection {
                HapticManager.shared.playWarning()
            }
            previousConnection = new
        }
        .onAppear {
            previousConnection = isConnected
        }
    }
}

// MARK: - Flick Service Card
struct FlickServiceCard: View {
    var isSelected: Bool
    var title: String
    var description: String
    var iconName: String
    var isSystemIcon: Bool = true
    var color: Color
    var isEnabled: Bool = true
    var action: (() -> Void)? = nil // Optional for standard buttons
    
    var body: some View {
        Button(action: {
            if isEnabled { action?() }
        }) {
            HStack(spacing: 16) {
                // Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color.opacity(0.1) : Color.white.opacity(0.05))
                        .frame(width: 50, height: 50)
                    
                    if isSystemIcon {
                        Image(systemName: iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(isSelected ? color : .gray)
                    } else {
                        Image(iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 38, height: 38)
                            .saturation(isSelected ? 1.0 : 0.0)
                            .opacity(isSelected ? 1.0 : 0.6)
                    }
                }
                
                // Text Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? color : .gray)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(color)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(18)
            .background {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(color)
                            .blur(radius: 9)
                            .opacity(0.55)
                            .padding(-8)
                    }
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? color.opacity(0.2) : Color.white.opacity(0.05))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.white.opacity(0.08), lineWidth: isSelected ? 2.5 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled || action == nil)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}
