//
//  DataCollectionView.swift
//  Flick
//
//  UI for collecting labeled training data - Refined "Lab" Edition
//

import SwiftUI
import Combine
import WatchConnectivity
import AVKit

struct DataCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataCollector = DataCollectionCoordinator()
    @State private var showHelpSheet = false
    
    // Cooldown logic to prevent accidental double-taps
    @State private var lastActionTime: Date = .distantPast
    @State private var totalRecordingTime = "00:00:00"
    private let toggleCooldown: TimeInterval = 1.0
    
    private var isWatchConnected: Bool {
        WCSession.default.isPaired && WCSession.default.isWatchAppInstalled
    }
    
    // Heartbeat timer
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                RadialGradient(
                    gradient: Gradient(colors: [dataCollector.isRecording || dataCollector.isSyncing ? .red.opacity(0.1) : .orange.opacity(0.1), .clear]),
                    center: .center,
                    startRadius: 10,
                    endRadius: 500
                )
                .ignoresSafeArea()
                
                // MARK: - Main Content State Switcher
                VStack(spacing: 0) {
                    if dataCollector.isSyncing || dataCollector.isProcessing {
                        // STATE 1: SYNCING (Front and Center)
                        syncingView
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                if dataCollector.isRecording {
                                    // STATE 2: RECORDING (The Grid)
                                    recordingHeader
                                    
                                    if dataCollector.isRecording || dataCollector.isSyncing || dataCollector.isProcessing {
                                        recordingStatusBar
                                            .transition(.move(edge: .top).combined(with: .opacity))
                                    }
                                    
                                    VStack(spacing: 16) {
                                        labGestureCard(title: "FLICK LEFT", sub: "Next Track", icon: "arrow.left.circle.fill", pressed: $dataCollector.flickLeftPressed)
                                        labGestureCard(title: "FLICK RIGHT", sub: "Prev Track", icon: "arrow.right.circle.fill", pressed: $dataCollector.flickRightPressed)
                                        labGestureCard(title: "UPSIDE DOWN", sub: "Play / Pause", icon: "arrow.down.to.line.circle.fill", pressed: $dataCollector.upsideDownPressed)
                                    }
                                    .padding(.horizontal)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    
                                } else {
                                    // STATE 3: INSTRUCTIONS (Not Recording)
                                    instructionView
                                        .transition(.opacity)
                                }
                                
                                Spacer(minLength: 140)
                            }
                        }
                    }
                }
                
                // MARK: - Bottom Action Button
                // Only show if not syncing
                if !dataCollector.isSyncing && !dataCollector.isProcessing {
                    VStack {
                        Spacer()
                        Button(action: {
                            let now = Date()
                            guard now.timeIntervalSince(lastActionTime) > toggleCooldown else { return }
                            
                            lastActionTime = now
                            HapticManager.shared.playSelection()
                            
                            if isWatchConnected {
                                if dataCollector.isRecording {
                                    totalRecordingTime = dataCollector.formattedDuration
                                }
                                dataCollector.toggleRecording()
                            } else {
                                HapticManager.shared.playWarning()
                                showHelpSheet = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: dataCollector.isRecording ? "stop.circle.fill" : "record.circle.fill")
                                    .font(.title3)
                                Text(dataCollector.isRecording ? "FINISH RECORDING" : "START RECORDING")
                                    .font(.system(.headline, design: .monospaced))
                                    .bold()
                            }
                            .frame(maxWidth: .infinity, minHeight: 45)
                            .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 30)
                        .tint(dataCollector.isRecording ? .red : .orange)
                        .flickProminentButton(tint: dataCollector.isRecording ? .red : .orange)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Data Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        HapticManager.shared.playImpact()
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        HapticManager.shared.playImpact()
                        showHelpSheet = true
                    }) {
                        Image(systemName: isWatchConnected ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                            .foregroundStyle(isWatchConnected ? .green : .red)
                            .fontWeight(.bold)
                            .symbolEffect(.pulse, isActive: !isWatchConnected)
                    }
                }
            }
            .onReceive(timer) { _ in
                if dataCollector.isRecording || dataCollector.isSyncing || dataCollector.isProcessing {
                    dataCollector.objectWillChange.send()
                }
            }
            .animation(.snappy, value: dataCollector.isRecording)
            .animation(.snappy, value: dataCollector.isSyncing)
        }
        .preferredColorScheme(.dark)
        
        // Diagnostics sheet
        .sheet(isPresented: $showHelpSheet) {
            ConnectionHelpView()
                .presentationDetents([.height(230), .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Sub-Views
    
    private var recordingHeader: some View {
        Text("Hold a button while performing a gesture.\nMove naturally during recording.")
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundStyle(.gray)
            .padding(.horizontal, 40)
            .padding(.top, 20)
    }
    
    private var instructionView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("Learn to Contribute")
                    .font(.title2.bold())
                Text("Data Collection trains Flick to detect gestures, reducing false positives and negatives.")
                    .font(.body)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // VIDEO PLACEHOLDER
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    }
                
                VStack(spacing: 16) {
                    Image(systemName: "play.rectangle.on.rectangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange.opacity(0.6))
                    Text("Instructional Video Placeholder")
                        .font(.caption.monospaced())
                        .foregroundStyle(.gray)
                }
                
                /*
                // To drop in your video:
                // 1. Add video file to Xcode project (e.g., "training_guide.mp4")
                // 2. Uncomment the VideoPlayer below:
                 
                VideoPlayer(player: AVPlayer(url: Bundle.main.url(forResource: "training_guide", withExtension: "mp4")!))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                */
            }
            .frame(height: 220)
            .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 16) {
                instructionRow(icon: "1.circle.fill", text: "Tap Start Recording below.")
                instructionRow(icon: "2.circle.fill", text: "If performing a gesture, hold the corresponding gesture card.")
                instructionRow(icon: "3.circle.fill", text: "Tap Finish Recording to save data.")
                instructionRow(icon: "4.circle.fill", text: "Share data with the creators of Flick.")
            }
            .padding(.horizontal, 40)
        }
    }
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }
    
    private var syncingView: some View {
            VStack(spacing: 40) {
                Spacer()
                
                // MARK: - Central Status Spinner
                ZStack {
                    // Outer ambient glow
                    Circle()
                        .stroke(Color.orange.opacity(0.1), lineWidth: 70)
                        .frame(width: 50, height: 140)
                        .blur(radius: 15)
                    
                    // Loading Spinner
                    ProgressView()
                        .scaleEffect(2.0)
                        .tint(.orange)
                }
                
                VStack(spacing: 24) {
                    Text(dataCollector.isProcessing ? "PROCESSING DATA" : "SYNCING DATA")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(.white)
                    
                    // Metadata Dock
                    HStack(spacing: 24) {
                        VStack(alignment: .center, spacing: 4) {
                            Text("DURATION")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.gray)
                            Text(totalRecordingTime)
                                .font(.system(.body, design: .monospaced))
                                .bold()
                        }
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1, height: 24)
                        
                        VStack(alignment: .center, spacing: 4) {
                            Text("SAMPLES")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.gray)
                            Text("\(dataCollector.gestureLabels.count)")
                                .font(.system(.body, design: .monospaced))
                                .bold()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                
                // Central Progress Tracker
                VStack(spacing: 16) {
                    if dataCollector.transferProgress > 0 {
                        ZStack(alignment: .leading) {
                            // Track
                            Capsule()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 240, height: 12)
                            
                            // Progress
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 240 * CGFloat(dataCollector.transferProgress), height: 12)
                                .shadow(color: .orange.opacity(0.3), radius: 6)
                        }
                        
                        Text("\(Int(dataCollector.transferProgress * 100))%")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.orange)
                            .bold()
                    } else {
                        // Waiting state for progress
                        Text("PREPARING TRANSFER...")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(.gray)
                            .opacity(0.5)
                    }
                }
                .animation(.spring(), value: dataCollector.transferProgress)
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal)
        }
    
    @ViewBuilder
    private func labGestureCard(title: String, sub: String, icon: String, pressed: Binding<Bool>) -> some View {
        FlickServiceCard(
            isSelected: pressed.wrappedValue,
            title: title,
            description: sub,
            iconName: icon,
            isSystemIcon: true,
            color: .orange,
            isEnabled: dataCollector.isRecording
        )
        .scaleEffect(pressed.wrappedValue ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed.wrappedValue)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if dataCollector.isRecording && !pressed.wrappedValue {
                        pressed.wrappedValue = true
                        HapticManager.shared.playImpact()
                    }
                }
                .onEnded { _ in
                    pressed.wrappedValue = false
                }
        )
    }

    private var recordingStatusBar: some View {
        HStack {
            HStack(spacing: 15) {
                Circle().fill(.red).frame(width: 8, height: 8)
                    .symbolEffect(.pulse, options: .repeating)
                Text(dataCollector.formattedDuration)
                    .font(.system(.body, design: .monospaced)).bold()
                Spacer()
                let sampleCount = dataCollector.gestureLabels.count
                Text(sampleCount != 1 ? "\(dataCollector.gestureLabels.count) SAMPLES" : "\(dataCollector.gestureLabels.count) SAMPLE")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.horizontal)
    }
}

#Preview {
    DataCollectionView()
}
