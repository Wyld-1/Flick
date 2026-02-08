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
                gradient: Gradient(colors: [.orange.opacity(0.15), .clear]),
                center: .center,
                startRadius: 10,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            // MARK: - Debug buttons
            #if DEBUG
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        var settings = SharedSettings.load()
                        settings.isTutorialCompleted = true
                        SharedSettings.save(settings)
                        
                        withAnimation {
                            appState.currentState = .welcome
                        }
                    }) {
                        Text("DEBUG: RESTART")
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
                    
                    Button(action: {
                        var settings = SharedSettings.load()
                        settings.isTutorialCompleted = true
                        SharedSettings.save(settings)
                        appState.goToMain()
                    }) {
                        Text("DEBUG: SKIP TO MAIN")
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
                .padding(.leading, 20)
                Spacer()
            }
            .zIndex(10)
            #endif
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    // Ripples
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.orange.opacity(0.3), lineWidth: 6)
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 2.3 : 1.3)
                            .opacity(isAnimating ? 0 : 0.3)
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
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showHelpSheet) {
            WatchConnectionHelpView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Subviews

struct GlassStatusDock: View {
    @Binding var showHelp: Bool
    
    // Accessing the singleton directly
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
}

struct WatchConnectionHelpView: View {
    @Environment(\.dismiss) var dismiss
    
    // Check WCSession diagnostics
    var session: WCSession { WCSession.default }
    var isPaired: Bool { session.isPaired }
    var isInstalled: Bool { session.isWatchAppInstalled }
    var isReachable: Bool { WatchConnectivityManager.shared.isReachable }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Connection Help")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.top, 24)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // MARK: - Smart Diagnostics
                        if !isPaired {
                            DiagnosticCard(
                                icon: "applewatch.slash",
                                title: "No Watch Paired",
                                description: "iOS can't find a paired Apple Watch.",
                                buttonTitle: "Pair Watch"
                            )
                        } else if !isInstalled {
                            DiagnosticCard(
                                icon: "app.dashed",
                                title: "Flick Not Installed",
                                description: "Flick is not installed on your Watch.",
                                buttonTitle: "Install Flick"
                            )
                        } else if isReachable {
                            // Success Check
                            HStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.green)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Watch Connected")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text("Flick should run normally.")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                            
                        } else {
                            // Standard Check: Wake Screen
                            HStack(spacing: 16) {
                                Image(systemName: "zzz")
                                    .font(.title)
                                    .foregroundStyle(.orange)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Wake Your Screen")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text("Flick sleeps to save battery. Raise your wrist to reconnect.")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // MARK: - Footer (Contact vs Troubleshooting)
                        
                        if isReachable {
                            Link(destination: URL(string: "https://forms.gle/RSBVKFks8jatoQLS8")!) {
                                HStack {
                                    Text("Connectivity issues? Contact Flick.")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.forward.app.fill")
                                        .foregroundStyle(.green)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        } else {
                            Divider().background(Color.gray.opacity(0.3))
                            
                            Text("Troubleshooting")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            VStack(alignment: .leading, spacing: 20) {
                                HelpRow(number: "1", text: "Ensure Bluetooth is on and Airplane Mode is off.")
                                HelpRow(number: "2", text: "Open Flick on your Watch.")
                                HelpRow(number: "3", text: "Force quit the iPhone app and restart.")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Diagnostic Helpers

struct DiagnosticCard: View {
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(.red)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                Spacer()
            }
            
            Link(destination: URL(string: "bridge://")!) { // Deep link to Watch App
                Text(buttonTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct HelpRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 32, height: 32)
                Text(number)
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
            
            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContinueOnWatchView()
        .environmentObject(AppStateManager())
}
