//
//  DataCollectionView.swift
//  Flick
//
//  UI for collecting labeled training data - Refined "Lab" Edition
//

import SwiftUI
import Combine

struct DataCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var collector = DataCollectionCoordinator()
    @State private var showHelpSheet = false
    
    // Heartbeat timer to force UI updates for the duration string
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [.orange.opacity(0.1), .clear]),
                center: .center,
                startRadius: 10,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        VStack(spacing: 24) {
                            VStack(spacing: 8) {
                                Text("Hold a button while performing a gesture.\nMove naturally during recording.")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Status Bar (Condition handled inside the var)
                        if collector.isRecording || collector.isSyncing || collector.isProcessing {
                            recordingStatusBar
                                .transition(.asymmetric(insertion: .push(from: .top), removal: .opacity))
                        }
                        
                        // Gesture Input Grid
                        VStack(spacing: 16) {
                            GestureButton(
                                title: "FLICK LEFT",
                                subtitle: "Next Track",
                                icon: "arrow.left.circle",
                                isPressed: $collector.flickLeftPressed,
                                isEnabled: collector.isRecording
                            )
                            
                            GestureButton(
                                title: "FLICK RIGHT",
                                subtitle: "Prev Track",
                                icon: "arrow.right.circle",
                                isPressed: $collector.flickRightPressed,
                                isEnabled: collector.isRecording
                            )
                            
                            GestureButton(
                                title: "UPSIDE DOWN",
                                subtitle: "Play / Pause",
                                icon: "arrow.down.to.line.circle",
                                isPressed: $collector.upsideDownPressed,
                                isEnabled: collector.isRecording
                            )
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 160) // Extra buffer for the bottom bar
                    }
                }
            }
            
            // MARK: - Fixed Bottom Control (FIXED GRAY RECTANGLE)
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    // Subtle line instead of the default gray Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                    
                    Button(action: {
                        HapticManager.shared.playSelection()
                        collector.toggleRecording()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: collector.isRecording ? "stop.circle.fill" : "record.circle")
                                .font(.title3)
                            Text(collector.isRecording ? "FINISH RECORDING" : "BEGIN RECORDING")
                                .font(.system(.headline, design: .monospaced))
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(VividGlassButtonStyle())
                    .tint(collector.isRecording ? .red : .orange)
                    .disabled(collector.isProcessing)
                    .opacity(collector.isProcessing ? 0.5 : 1.0)
                    .padding(.horizontal, 30)
                    .padding(.top, 25)
                    .padding(.bottom, 40) // Increased for better thumb reach
                }
                // THE FIX: Adding the background to the VStack and ignoring safe area
                .background(
                    Color.black.opacity(0.85)
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Data Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                GlassStatusDock(showHelp: $showHelpSheet)
                    .scaleEffect(0.65)
            }
        }
        .sheet(isPresented: $showHelpSheet) {
            ConnectionHelpView()
                .presentationDetents([.height(230), .large])
                .presentationDragIndicator(.visible)
        }
        // HEARTBEAT: Keeps the duration string updating in real-time
        .onReceive(timer) { _ in
            if collector.isRecording || collector.isSyncing {
                collector.objectWillChange.send()
            }
        }
    }
    
    private var watchStatusText: String {
        let state = SharedSettings.load().dataCollectionState
        switch state {
        case .off: return "IDLE"
        case .recording: return "REC"
        case .syncing: return "SYNC"
        }
    }
    
    private var watchStatusColor: Color {
        let state = SharedSettings.load().dataCollectionState
        switch state {
        case .off: return .gray
        case .recording: return .green
        case .syncing: return .orange
        }
    }
    
    // MARK: - Private Sub-Views
    
    private var recordingStatusBar: some View {
        HStack {
            if collector.isProcessing || collector.isSyncing {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        ProgressView().tint(.orange)
                        Text(collector.syncProgress.isEmpty ? "SYNCING..." : collector.syncProgress.uppercased())
                            .font(.system(.caption, design: .monospaced))
                            .bold()
                    }
                    
                    // Progress bar if transferring
                    if collector.transferProgress > 0 && collector.transferProgress < 1.0 {
                        ProgressView(value: collector.transferProgress)
                            .tint(.orange)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                HStack(spacing: 15) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .symbolEffect(.pulse, options: .repeating)
                    
                    Text(collector.formattedDuration)
                        .font(.system(.body, design: .monospaced))
                        .bold()
                        .contentTransition(.numericText())
                    
                    Spacer()
                    
                    Text("\(collector.gestureLabels.count) SAMPLES")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    Divider().frame(height: 12).background(.white.opacity(0.2))
                    
                    // Watch status based on shared state
                    HStack(spacing: 4) {
                        Image(systemName: "applewatch")
                        Text(watchStatusText)
                            .font(.system(.caption2, design: .monospaced))
                    }
                    .foregroundStyle(watchStatusColor)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.horizontal)
    }
}

// MARK: - Gesture Button View

struct GestureButton: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isPressed: Bool
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 54, height: 54)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isPressed ? .green : (isEnabled ? .white : .gray))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(isEnabled ? .white : .gray)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isPressed {
                Image(systemName: "recording.circle.fill")
                    .foregroundStyle(.green)
                    .symbolEffect(.pulse, options: .repeating)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .opacity(isPressed ? 1.0 : 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isPressed ? Color.green : Color.white.opacity(0.1), lineWidth: isPressed ? 2 : 1)
        )
        .opacity(isEnabled ? 1.0 : 0.4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled && !isPressed {
                        HapticManager.shared.playImpact()
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    DataCollectionView()
}
