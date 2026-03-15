//
//  DataCollectionManager.swift
//  Flick Watch App
//
//  Records sensor data for ML model training
//  Observes SharedSettings.dataCollectionState as single source of truth
//

import Foundation
import CoreMotion
import WatchKit
import Combine

class DataCollectionManager: ObservableObject {
    static let shared = DataCollectionManager()
    
    @Published var sampleCount = 0
    @Published var duration: TimeInterval = 0
    
    // Observe the shared state - don't maintain local state
    var currentState: DataCollectionState {
        SharedSettings.load().dataCollectionState
    }
    
    private var samples: [MotionSample] = []
    private let motion = CMMotionManager()
    private let maxDuration: TimeInterval = 3 * 60 * 60  // 3 hours
    private var startTime: Date?
    private var durationTimer: Timer?
    private var stateObserver: NSObjectProtocol?
    
    private init() {
        // Listen for state changes from SharedSettings
        stateObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleStateChange()
        }
    }
    
    deinit {
        if let observer = stateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // React to state changes from SharedSettings
    private func handleStateChange() {
        let state = currentState
        print("⌚️ [TELEMETRY] DataCollectionManager: State changed to \(state)")
        print("⌚️ [TELEMETRY] motion.isDeviceMotionActive: \(motion.isDeviceMotionActive)")
        
        // Trigger UI update
        objectWillChange.send()
        
        switch state {
        case .off:
            print("⌚️ [TELEMETRY] Handling .off state")
            // Clean up if needed
            if motion.isDeviceMotionActive {
                print("⌚️ [TELEMETRY] Stopping motion sensors")
                stopRecording()
            } else {
                print("⌚️ [TELEMETRY] Motion already stopped")
            }
            
        case .recording:
            print("⌚️ [TELEMETRY] Handling .recording state")
            // Start recording if not already
            if !motion.isDeviceMotionActive {
                print("⌚️ [TELEMETRY] Starting recording")
                startRecording()
            } else {
                print("⌚️ [TELEMETRY] Already recording")
            }
            
        case .syncing:
            print("⌚️ [TELEMETRY] Handling .syncing state")
            // CRITICAL FIX: Always send data, regardless of motion state
            // In simulator, motion is never active, but we still need to send the empty file
            stopAndSendData()
        }
    }
    
    private func startRecording() {
        samples = []
        sampleCount = 0
        duration = 0
        startTime = Date()
        
        print("⌚️ Starting data collection")
        WKInterfaceDevice.current().play(.start)
        
        // Start duration timer
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.duration = Date().timeIntervalSince(start)
        }
        
        // Start motion updates at 50Hz
        #if !targetEnvironment(simulator)
        motion.deviceMotionUpdateInterval = 0.02
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            self.recordSample(data)
        }
        #else
        print("⌚️ Simulator - motion sensors disabled")
        #endif
        
        // Auto-stop after 3 hours
        DispatchQueue.main.asyncAfter(deadline: .now() + maxDuration) { [weak self] in
            guard let self = self else { return }
            // Set state to syncing (iPhone will update SharedSettings)
            var settings = SharedSettings.load()
            if settings.dataCollectionState == .recording {
                settings.dataCollectionState = .syncing
                SharedSettings.save(settings)
            }
        }
    }
    
    private func stopRecording() {
        motion.stopDeviceMotionUpdates()
        durationTimer?.invalidate()
        durationTimer = nil
        print("⌚️ Stopped recording")
    }
    
    private func stopAndSendData() {
        print("⌚️ [TELEMETRY] stopAndSendData() called")
        
        stopRecording()
        
        print("⌚️ [TELEMETRY] Syncing - collected \(samples.count) samples")
        
        // Send to iPhone
        print("⌚️ [TELEMETRY] Calling sendToiPhone()...")
        sendToiPhone()
        print("⌚️ [TELEMETRY] sendToiPhone() returned")
    }
    
    private func recordSample(_ data: CMDeviceMotion) {
        let sample = MotionSample(
            timestamp: Date().timeIntervalSinceReferenceDate,
            rotationX: data.rotationRate.x,
            rotationY: data.rotationRate.y,
            rotationZ: data.rotationRate.z,
            gravityX: data.gravity.x,
            gravityY: data.gravity.y,
            gravityZ: data.gravity.z,
            userAccelX: data.userAcceleration.x,
            userAccelY: data.userAcceleration.y,
            userAccelZ: data.userAcceleration.z
        )
        
        samples.append(sample)
        sampleCount = samples.count
    }
    
    private func sendToiPhone() {
        print("⌚️ [TELEMETRY] sendToiPhone() called")
        
        // In simulator or with no samples, create minimal valid file
        let data: Data
        let filename: String
        
        if samples.isEmpty {
            print("⌚️ [TELEMETRY] No samples collected (creating empty file)")
            data = "[]".data(using: .utf8)!
            filename = "motion_data_empty_\(Date().timeIntervalSince1970).json"
        } else {
            print("⌚️ [TELEMETRY] Encoding \(samples.count) samples to JSON")
            // Encode samples to JSON
            let encoder = JSONEncoder()
            guard let encoded = try? encoder.encode(samples) else {
                print("⌚️ [TELEMETRY] ❌ Failed to encode samples")
                WKInterfaceDevice.current().play(.failure)
                returnToOff()
                return
            }
            data = encoded
            filename = "motion_data_\(Date().timeIntervalSince1970).json"
            print("⌚️ [TELEMETRY] ✅ Encoded \(data.count) bytes")
        }
        
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        print("⌚️ [TELEMETRY] Creating temp file at: \(tempURL.path)")
        
        do {
            try data.write(to: tempURL)
            print("⌚️ [TELEMETRY] ✅ File written successfully")
            print("⌚️ [TELEMETRY] Calling WatchConnectivityManager.sendFile()")
            
            // Send via WatchConnectivity
            WatchConnectivityManager.shared.sendFile(tempURL)
            
            print("⌚️ [TELEMETRY] sendFile() returned - waiting for completion")
            WKInterfaceDevice.current().play(.success)
            
            // Return to off state after brief delay
            print("⌚️ [TELEMETRY] Scheduling returnToOff() in 2 seconds")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("⌚️ [TELEMETRY] Delay completed - calling returnToOff()")
                self.returnToOff()
            }
        } catch {
            print("⌚️ [TELEMETRY] ❌ Error writing file: \(error)")
            WKInterfaceDevice.current().play(.failure)
            returnToOff()
        }
    }
    
    private func returnToOff() {
        print("⌚️ [TELEMETRY] returnToOff() called")
        var settings = SharedSettings.load()
        print("⌚️ [TELEMETRY] Current state before change: \(settings.dataCollectionState)")
        settings.dataCollectionState = .off
        SharedSettings.save(settings)
        print("⌚️ [TELEMETRY] ✅ State set to .off and saved")
        
        // Verify it saved
        let verification = SharedSettings.load()
        print("⌚️ [TELEMETRY] Verification - state is now: \(verification.dataCollectionState)")
        
        // Force UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
            print("⌚️ [TELEMETRY] ✅ Triggered objectWillChange for UI update")
        }
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
