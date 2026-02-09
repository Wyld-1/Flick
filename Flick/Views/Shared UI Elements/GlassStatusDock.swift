//
//  GlassStatusDock.swift
//  Flick
//
//  Reusable connection status dock
//

import SwiftUI
import WatchConnectivity

struct GlassStatusDock: View {
    @Binding var showHelp: Bool
    @State private var previousReachability = false
    
    var isReachable: Bool {
        WatchConnectivityManager.shared.isReachable
    }
    
    var body: some View {
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
            // Haptic feedback on connection state change
            if new && !previousReachability {
                // Just connected
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } else if !new && previousReachability {
                // Just disconnected
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
            previousReachability = new
        }
        .onAppear {
            previousReachability = isReachable
        }
    }
}
