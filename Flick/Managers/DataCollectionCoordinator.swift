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
    @Published var syncProgress: String = ""
    @Published var transferProgress: Double = 0.0
    
    var isRecording: Bool {
        SharedSettings.load().dataCollectionState == .recording
    }
    
    var isSyncing: Bool {
        SharedSettings.load().dataCollectionState == .syncing
    }
    
    private var mStartTime: Date?
    private var mCurrentGestureStart: [String: TimeInterval] = [:]
    private var mDataObserver: NSObjectProtocol?
    private var mStateObserver: NSObjectProtocol?
    
    init() {
        mDataObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WatchDataReceived"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let samples = notification.object as? [MotionSample] else { return }
            self?.syncProgress = "Processing \(samples.count) samples..."
            self?.processWatchData(samples)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("FileTransferProgress"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let progress = notification.object as? Double else { return }
            self?.transferProgress = progress
            if progress < 1.0 {
                self?.syncProgress = "Transferring data: \(Int(progress * 100))%"
            }
        }
        
        // Show initial "encoding" message when the Watch starts syncing
        mStateObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if SharedSettings.load().dataCollectionState == .syncing && self.syncProgress.isEmpty {
                self.syncProgress = "Watch is encoding data..."
            }
            self.objectWillChange.send()
        }
    }
    
    deinit {
        if let observer = mDataObserver { NotificationCenter.default.removeObserver(observer) }
        if let observer = mStateObserver { NotificationCenter.default.removeObserver(observer) }
    }
    
    var formattedDuration: String {
        guard let start = mStartTime else { return "00:00:00" }
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
        mCurrentGestureStart = [:]
        mStartTime = Date()
        syncProgress = ""
        transferProgress = 0.0
        var settings = SharedSettings.load()
        settings.dataCollectionState = .recording
        SharedSettings.save(settings)
        HapticManager.shared.playImpact()
        print("📱 Started data collection")
        objectWillChange.send()
    }
    
    private func finishRecording() {
        // Close any gestures still held when recording stops
        for (gestureType, startTime) in mCurrentGestureStart {
            gestureLabels.append(GestureLabel(
                startTime: startTime,
                endTime: Date().timeIntervalSinceReferenceDate,
                gestureType: gestureType
            ))
        }
        mCurrentGestureStart = [:]
        var settings = SharedSettings.load()
        settings.dataCollectionState = .syncing
        SharedSettings.save(settings)
        syncProgress = "Waiting for Watch to sync..."
        HapticManager.shared.playImpact()
        print("📱 Finished recording with \(gestureLabels.count) gesture labels")
        objectWillChange.send()
    }
    
    private func handleButtonChange(_ gestureType: String, _ isPressed: Bool) {
        guard isRecording else { return }
        let timestamp = Date().timeIntervalSinceReferenceDate
        if isPressed {
            mCurrentGestureStart[gestureType] = timestamp
            HapticManager.shared.playImpact()
        } else if let startTime = mCurrentGestureStart[gestureType] {
            gestureLabels.append(GestureLabel(
                startTime: startTime,
                endTime: timestamp,
                gestureType: gestureType
            ))
            mCurrentGestureStart[gestureType] = nil
            HapticManager.shared.playImpact()
            print("📱 Labeled gesture: \(gestureType) from \(startTime) to \(timestamp)")
        }
    }
    
    func processWatchData(_ samples: [MotionSample]) {
        print("📱 processWatchData() - \(samples.count) samples, \(gestureLabels.count) labels")
        isProcessing = true
        syncProgress = "Generating CSV file..."
        let csv = generateCSV(samples: samples, labels: gestureLabels)
        syncProgress = "Saving to file..."
        saveCSV(csv)
        var settings = SharedSettings.load()
        settings.dataCollectionState = .off
        SharedSettings.save(settings)
        isProcessing = false
        syncProgress = "Complete!"
        transferProgress = 1.0
        HapticManager.shared.playSuccess()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.syncProgress = ""
            self.transferProgress = 0.0
        }
        objectWillChange.send()
    }
    
    private func generateCSV(samples: [MotionSample], labels: [GestureLabel]) -> String {
        var csv = "timestamp,rotX,rotY,rotZ,gravX,gravY,gravZ,userAccelX,userAccelY,userAccelZ,label\n"
        for sample in samples {
            let label = labels.first {
                sample.timestamp >= $0.startTime && sample.timestamp <= $0.endTime
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
            shareFile(url)
        } catch {
            print("📱 Error saving CSV: \(error)")
        }
    }
    
    private func shareFile(_ url: URL) {
        #if targetEnvironment(simulator)
        print("📱 Share sheet unavailable in simulator. File at: \(url.path)")
        #endif
        
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = scene.windows.first?.rootViewController else {
                print("📱 Could not find root view controller")
                return
            }
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            // iPad popover anchor
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                           y: rootViewController.view.bounds.midY,
                                           width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootViewController.present(activityVC, animated: true)
        }
    }
}
