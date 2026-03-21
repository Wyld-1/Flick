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
    
    private var mSamples: [MotionSample] = []
    private let mMotion = CMMotionManager()
    private let MAX_DURATION: TimeInterval = 3 * 60 * 60  // 3 hours
    private var mStartTime: Date?
    private var mDurationTimer: Timer?
    private var mStateObserver: NSObjectProtocol?
    
    private init() {
        mStateObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleStateChange()
        }
    }
    
    deinit {
        if let observer = mStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func handleStateChange() {
        objectWillChange.send()
        switch currentState {
        case .off:
            if mMotion.isDeviceMotionActive { stopRecording() }
        case .recording:
            if !mMotion.isDeviceMotionActive { startRecording() }
        case .syncing:
            // Always send — even an empty file, so iPhone can reset state
            stopAndSendData()
        }
    }
    
    private func startRecording() {
        mSamples = []
        sampleCount = 0
        duration = 0
        mStartTime = Date()
        WKInterfaceDevice.current().play(.start)
        print("⌚️ Starting data collection")
        
        mDurationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.mStartTime else { return }
            self.duration = Date().timeIntervalSince(start)
        }
        
        #if !targetEnvironment(simulator)
        mMotion.deviceMotionUpdateInterval = 0.02  // 50Hz
        mMotion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            self.recordSample(data)
        }
        #endif
        
        // Auto-stop after MAX_DURATION
        DispatchQueue.main.asyncAfter(deadline: .now() + MAX_DURATION) { [weak self] in
            guard let self = self else { return }
            var settings = SharedSettings.load()
            if settings.dataCollectionState == .recording {
                settings.dataCollectionState = .syncing
                SharedSettings.save(settings)
            }
        }
    }
    
    private func stopRecording() {
        mMotion.stopDeviceMotionUpdates()
        mDurationTimer?.invalidate()
        mDurationTimer = nil
        print("⌚️ Stopped recording")
    }
    
    private func stopAndSendData() {
        stopRecording()
        print("⌚️ Syncing - collected \(mSamples.count) samples")
        sendToiPhone()
    }
    
    private func recordSample(_ data: CMDeviceMotion) {
        mSamples.append(MotionSample(
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
        ))
        sampleCount = mSamples.count
    }
    
    private func sendToiPhone() {
        let data: Data
        let filename: String
        
        if mSamples.isEmpty {
            // Send an empty JSON array so iPhone can still reset state
            data = "[]".data(using: .utf8)!
            filename = "motion_data_empty_\(Date().timeIntervalSince1970).json"
        } else {
            guard let encoded = try? JSONEncoder().encode(mSamples) else {
                print("⌚️ Failed to encode samples")
                WKInterfaceDevice.current().play(.failure)
                returnToOff()
                return
            }
            data = encoded
            filename = "motion_data_\(Date().timeIntervalSince1970).json"
            print("⌚️ Encoded \(data.count) bytes")
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: tempURL)
            WatchConnectivityManager.shared.sendFile(tempURL)
            WKInterfaceDevice.current().play(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.returnToOff()
            }
        } catch {
            print("⌚️ Error writing file: \(error)")
            WKInterfaceDevice.current().play(.failure)
            returnToOff()
        }
    }
    
    private func returnToOff() {
        var settings = SharedSettings.load()
        settings.dataCollectionState = .off
        SharedSettings.save(settings)
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
