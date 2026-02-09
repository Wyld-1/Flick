//
//  WatchConnectionHelpView.swift
//  Flick
//
//  Diagnostics and troubleshooting for Watch connection
//

import SwiftUI
import WatchConnectivity

struct WatchConnectionHelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isReachable = WatchConnectivityManager.shared.isReachable
    
    // Diagnostics
    private var isPaired: Bool {
        WCSession.default.isPaired
    }
    
    private var isInstalled: Bool {
        WCSession.default.isWatchAppInstalled
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
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
                                buttonTitle: "Pair Watch",
                                url: "x-apple-watchapp://" // Opens Watch app
                            )
                        } else if !isInstalled {
                            DiagnosticCard(
                                icon: "app.dashed",
                                title: "Flick Not Installed",
                                description: "Flick is not installed on your Watch.",
                                buttonTitle: "Install Flick",
                                url: "x-apple-watchapp://" // Opens Watch app
                            )
                        } else if isReachable {
                            // Success Check with celebration
                            HStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.green)
                                    .frame(width: 40)
                                    .symbolEffect(.bounce, value: isReachable)
                                
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
                            .transition(.scale.combined(with: .opacity))
                            
                        } else {
                            // Standard Check: Wake Screen
                            HStack(spacing: 16) {
                                Image(systemName: "zzz")
                                    .font(.title)
                                    .foregroundStyle(.orange)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Wake Your Watch")
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
                                    Text("Still having issues? Contact Flick.")
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
        // Auto-refresh when connection state changes
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SettingsDidUpdate"))) { _ in
            isReachable = WatchConnectivityManager.shared.isReachable
        }
        .onChange(of: WatchConnectivityManager.shared.isReachable) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isReachable = newValue
            }
            
            // Celebrate if just connected
            if newValue {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Helper Views

struct DiagnosticCard: View {
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    let url: String
    
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
            
            Link(destination: URL(string: url)!) {
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

#Preview {
    WatchConnectionHelpView()
}
