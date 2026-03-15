//
//  DataCollectionCoordinator.swift
//  Flick
//
//  Coordinates ML data collection
//  Controls dataCollectionState in SharedSettings (single source of truth)
//

import Foundation
import UIKit
import Combine

class DataCollectionCoordinator: ObservableObject {
    @Published var flickLeftPressed = false { didSet { handleButtonChange("FlickLeft", flickLeftPressed) } }
    @Published var flickRightPressed = false { didSet { handleButtonChange("FlickRight", flickRightPressed) } }
    @Published var upsideDownPressed = false { didSet { handleButtonChange("HoldUpsideDown", upsideDownPressed) } }
    @Published var gestureLabels: [GestureLabel] = []
    @Published var isProcessing = false
    @Published var syncProgress: String = "" // Progress message during sync
    @Published var transferProgress: Double = 0.0 // File transfer progress 0.0-1.0
    
    // Computed from SharedSettings
    var isRecording: Bool {
        SharedSettings.load().dataCollectionState == .recording
    }
    
    var isSyncing: Bool {
        SharedSettings.load().dataCollectionState == .syncing
    }
    
    private var startTime: Date?
    private var currentGestureStart: [String: TimeInterval] = [:]
    private var dataObserver: NSObjectProtocol?
    private var stateObserver: NSObjectProtocol?
    
    init() {
        // Listen for Watch data
        dataObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WatchDataReceived"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let samples = notification.object as? [MotionSample] else { return }
            self?.transferProgress = 1.0
            self?.syncProgress = "Processing \(samples.count) samples..."
            self?.processWatchData(samples)
        }
        
        // Listen for transfer progress updates
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("FileTransferProgress"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let progress = notification.object as? Double {
                self?.transferProgress = progress
                if progress < 1.0 {
                    self?.syncProgress = "Transferring data: \(Int(progress * 100))%"
                }
            }
        }
        
        // Listen for settings updates to track sync state
        stateObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let state = SharedSettings.load().dataCollectionState
            
            switch state {
            case .recording:
                self.syncProgress = ""
                self.transferProgress = 0.0
            case .syncing:
                if self.syncProgress.isEmpty {
                    self.syncProgress = "Watch is encoding data..."
                }
                self.transferProgress = 0.0
            case .off:
                if !self.syncProgress.isEmpty && self.syncProgress != "Complete!" {
                    self.syncProgress = "Complete!"
                    self.transferProgress = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.syncProgress = ""
                        self.transferProgress = 0.0
                    }
                }
            }
            
            self.objectWillChange.send()
        }
    }
    
    deinit {
        if let observer = dataObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = stateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    var formattedDuration: String {
        guard let start = startTime else { return "00:00:00" }
        let elapsed = Date().timeIntervalSince(start)
        return String(format: "%02d:%02d:%02d", 
            Int(elapsed) / 3600,
            (Int(elapsed) % 3600) / 60,
            Int(elapsed) % 60)
    }
    
    func toggleRecording() {
        let currentState = SharedSettings.load().dataCollectionState
        
        switch currentState {
        case .off:
            startRecording()
        case .recording:
            finishRecording()
        case .syncing:
            print("📱 Already syncing - wait for completion")
        }
    }
    
    private func startRecording() {
        gestureLabels = []
        currentGestureStart = [:]
        startTime = Date()
        syncProgress = ""
        
        // Update state in SharedSettings (Watch will observe this)
        var settings = SharedSettings.load()
        settings.dataCollectionState = .recording
        SharedSettings.save(settings)
        
        HapticManager.shared.playImpact()
        print("📱 Started data collection - state set to .recording")
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    private func finishRecording() {
        // Force-end any active gestures
        for (gestureType, startTime) in currentGestureStart {
            let label = GestureLabel(
                startTime: startTime,
                endTime: Date().timeIntervalSinceReferenceDate,
                gestureType: gestureType
            )
            gestureLabels.append(label)
        }
        currentGestureStart = [:]
        
        // Update state in SharedSettings (Watch will observe and send data)
        var settings = SharedSettings.load()
        settings.dataCollectionState = .syncing
        SharedSettings.save(settings)
        
        syncProgress = "Waiting for Watch to sync..."
        
        HapticManager.shared.playImpact()
        print("📱 Finished recording with \(gestureLabels.count) gesture labels - state set to .syncing")
        print("📱 Waiting for Watch data...")
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    private func handleButtonChange(_ gestureType: String, _ isPressed: Bool) {
        guard isRecording else { return }
        
        let timestamp = Date().timeIntervalSinceReferenceDate
        
        if isPressed {
            // Button pressed - record start time
            currentGestureStart[gestureType] = timestamp
            HapticManager.shared.playImpact()
        } else if let startTime = currentGestureStart[gestureType] {
            // Button released - create label
            let label = GestureLabel(
                startTime: startTime,
                endTime: timestamp,
                gestureType: gestureType
            )
            gestureLabels.append(label)
            currentGestureStart[gestureType] = nil
            HapticManager.shared.playImpact()
            
            print("📱 Labeled gesture: \(gestureType) from \(startTime) to \(timestamp)")
        }
    }
    
    func processWatchData(_ samples: [MotionSample]) {
        print("📱 [TELEMETRY] processWatchData() called")
        print("📱 [TELEMETRY] Samples: \(samples.count), Labels: \(gestureLabels.count)")
        
        isProcessing = true
        syncProgress = "Generating CSV file..."
        print("📱 [TELEMETRY] isProcessing set to true")
        
        // Generate CSV
        print("📱 [TELEMETRY] Generating CSV...")
        let csv = generateCSV(samples: samples, labels: gestureLabels)
        print("📱 [TELEMETRY] ✅ CSV generated")
        
        syncProgress = "Saving to file..."
        
        // Save to file
        print("📱 [TELEMETRY] Saving CSV...")
        saveCSV(csv)
        print("📱 [TELEMETRY] ✅ CSV saved")
        
        // Reset state to off
        print("📱 [TELEMETRY] Resetting state to .off")
        var settings = SharedSettings.load()
        settings.dataCollectionState = .off
        SharedSettings.save(settings)
        print("📱 [TELEMETRY] ✅ State set to .off")
        
        isProcessing = false
        syncProgress = "Complete!"
        transferProgress = 1.0
        HapticManager.shared.playSuccess()
        
        // Clear progress message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.syncProgress = ""
            self.transferProgress = 0.0
        }
        
        // Trigger UI update
        objectWillChange.send()
        print("📱 [TELEMETRY] ✅ Processing complete")
    }
    
    private func generateCSV(samples: [MotionSample], labels: [GestureLabel]) -> String {
        var csv = "timestamp,rotX,rotY,rotZ,gravX,gravY,gravZ,userAccelX,userAccelY,userAccelZ,label\n"
        
        if samples.isEmpty {
            // No samples - just return header
            print("📱 No samples received - creating header-only CSV")
            return csv
        }
        
        for sample in samples {
            // Find matching label
            let label = labels.first { label in
                sample.timestamp >= label.startTime && sample.timestamp <= label.endTime
            }?.gestureType ?? "None"
            
            csv += "\(sample.timestamp),\(sample.rotationX),\(sample.rotationY),\(sample.rotationZ),"
            csv += "\(sample.gravityX),\(sample.gravityY),\(sample.gravityZ),"
            csv += "\(sample.userAccelX),\(sample.userAccelY),\(sample.userAccelZ),\(label)\n"
        }
        
        return csv
    }
    
    private func saveCSV(_ csv: String) {
        let filename = "flick_training_\(Date().timeIntervalSince1970).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            print("📱 Saved CSV to: \(url)")
            
            // Share via activity controller
            shareFile(url)
        } catch {
            print("📱 Error saving CSV: \(error)")
        }
    }
    
    private func shareFile(_ url: URL) {
        print("📱 [TELEMETRY] shareFile() called with: \(url.path)")
        
        #if targetEnvironment(simulator)
        print("📱 [SIMULATOR NOTE] Share sheet may not work properly in simulator")
        print("📱 [SIMULATOR NOTE] File is at: \(url.path)")
        print("📱 [SIMULATOR NOTE] On real device, share sheet will allow saving to Files app")
        #endif
        
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = scene.windows.first?.rootViewController else {
                print("📱 [TELEMETRY] ❌ Could not find root view controller")
                return
            }
            
            print("📱 [TELEMETRY] Presenting share sheet...")
            
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                           y: rootViewController.view.bounds.midY,
                                           width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true) {
                print("📱 [TELEMETRY] ✅ Share sheet presented")
            }
        }
    }
}
