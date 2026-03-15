//
//  WatchConnectivityManager.swift
//  Flick
//
//  Manages communication between Watch and iPhone
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isReachable = false
    
    // Command queue for retry mechanism
    private var commandQueue: [MediaCommand] = []
    private var retryTimer: Timer?
    
    // File transfer progress tracking
    private var progressObserver: NSKeyValueObservation?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Send Command (Watch → iPhone)
    func sendMediaCommand(_ command: MediaCommand) {
        guard WCSession.default.activationState == .activated else {
            print("❌ WCSession not activated")
            queueCommand(command)
            return
        }
        
        let message = ["command": command.rawValue]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: { reply in
                print("✅ Command sent: \(command.rawValue)")
                self.clearRetryTimer()
            }, errorHandler: { error in
                print("❌ Error sending command: \(error.localizedDescription)")
                self.queueCommand(command)
            })
        } else {
            print("❌ iPhone not reachable, queuing command")
            queueCommand(command)
        }
    }
    
    // MARK: - Command Queue & Retry
    private func queueCommand(_ command: MediaCommand) {
            // OPTIMIZATION: Don't let the queue grow forever.
            // If we have > 3 commands pending, drop the oldest one.
            if commandQueue.count > 3 {
                commandQueue.removeFirst()
            }
            
            commandQueue.append(command)
            startRetryTimer()
        }
    
    private func startRetryTimer() {
        guard retryTimer == nil else { return }
        
        retryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.retryQueuedCommands()
        }
    }
    
    private func retryQueuedCommands() {
        guard !commandQueue.isEmpty, WCSession.default.isReachable else { return }
        
        // Send all queued commands
        let commands = commandQueue
        commandQueue.removeAll()
        
        for command in commands {
            sendMediaCommand(command)
        }
    }
    
    private func clearRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = nil
        commandQueue.removeAll()
    }
    
    // MARK: - Settings Sync
    func syncSettings(_ settings: AppSettings) {
        guard WCSession.default.activationState == .activated else { return }
        
        do {
            let data = try JSONEncoder().encode(settings)
            let dict = ["settings": data]
            
            try WCSession.default.updateApplicationContext(dict)
            print("✅ Settings synced")
        } catch {
            print("❌ Error syncing settings: \(error)")
        }
    }
    
    // MARK: - File Transfer
    func sendFile(_ fileURL: URL) {
        print("⌚️ [TELEMETRY] sendFile() called with: \(fileURL.lastPathComponent)")
        
        guard WCSession.default.activationState == .activated else {
            print("⌚️ [TELEMETRY] ❌ Cannot send file - session not activated (state: \(WCSession.default.activationState.rawValue))")
            return
        }
        
        let metadata = ["type": "motionData", "filename": fileURL.lastPathComponent]
        let transfer = WCSession.default.transferFile(fileURL, metadata: metadata)
        print("⌚️ [TELEMETRY] ✅ File transfer initiated - isTransferring: \(transfer.isTransferring)")
        print("⌚️ [TELEMETRY] Transfer progress: \(transfer.progress.fractionCompleted)")
        
        // Observe transfer progress
        progressObserver = transfer.progress.observe(\.fractionCompleted, options: [.new]) { progress, _ in
            DispatchQueue.main.async {
                let fraction = progress.fractionCompleted
                print("⌚️ [TELEMETRY] Transfer progress: \(Int(fraction * 100))%")
                NotificationCenter.default.post(
                    name: NSNotification.Name("FileTransferProgress"),
                    object: fraction
                )
            }
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("📱 WCSession activated: \(activationState.rawValue)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("📱 Reachability changed: \(session.isReachable)")
            
            // Try to send queued commands when connection restored
            if session.isReachable {
                self.retryQueuedCommands()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
            #if os(iOS)
            print("📱 iPhone received message: \(message)")
            
            // Immedietly send the receipt to satisfy the Watch
            replyHandler(["status": "received"])
            
            // Process the command
            if let commandString = message["command"] as? String,
               let command = MediaCommand(rawValue: commandString) {
                DispatchQueue.main.async {
                    iOSMediaManager.shared.handleCommand(command)
                }
            }
            #else
            // Watch side - no message handling needed
            // Data collection controlled via SharedSettings state
            print("⌚️ Watch received message: \(message)")
            replyHandler(["status": "received"])
            #endif
        }
    
    // MARK: - Receive Application Context (Both sides)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        #if os(iOS)
        print("📱 Received application context: \(applicationContext.keys)")
        #else
        print("⌚️ Received application context: \(applicationContext.keys)")
        #endif
        
        // CRITICAL: Decode and SAVE the received settings to App Group
        guard let settingsData = applicationContext["settings"] as? Data else {
            print("❌ No settings data in context")
            return
        }
        
        do {
            let receivedSettings = try JSONDecoder().decode(AppSettings.self, from: settingsData)
            
            // Save to App Group storage (single source of truth)
            if let defaults = UserDefaults(suiteName: "group.flickplayback.SharedFiles") {
                let encoded = try JSONEncoder().encode(receivedSettings)
                defaults.set(encoded, forKey: "appSettings")
                defaults.synchronize()
            }
            
            #if os(iOS)
            print("✅ Settings synced from Watch - tutorial: \(receivedSettings.isTutorialCompleted), setup: \(receivedSettings.hasCompletedInitialSetup)")
            
            // Notify AppStateManager that settings changed
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("SettingsDidUpdate"), object: nil)
                print("📱 Posted SettingsDidUpdate notification")
            }
            #else
            print("✅ Settings synced from iPhone - method: \(receivedSettings.playbackMethod)")
            
            // Notify Watch AppStateManager to reload
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("SettingsDidUpdate"), object: nil)
            }
            #endif
        } catch {
            print("❌ Failed to decode settings: \(error)")
        }
    }
    
    // MARK: - Receive Messages (iPhone side)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        #if os(iOS)
        print("📱 iPhone received message: \(message)")
        
        if let commandString = message["command"] as? String,
           let command = MediaCommand(rawValue: commandString) {
            DispatchQueue.main.async {
                iOSMediaManager.shared.handleCommand(command)
            }
        }
        #endif
    }
    
    // MARK: - Receive File Transfer (iPhone)
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("📱 [TELEMETRY] iPhone received file: \(file.fileURL.lastPathComponent)")
        print("📱 [TELEMETRY] File URL: \(file.fileURL.path)")
        print("📱 [TELEMETRY] Metadata: \(String(describing: file.metadata))")
        
        guard let type = file.metadata?["type"] as? String, type == "motionData" else {
            print("📱 [TELEMETRY] ❌ Unknown file type")
            return
        }
        
        print("📱 [TELEMETRY] Reading file data...")
        
        // Decode samples
        let decoder = JSONDecoder()
        guard let data = try? Data(contentsOf: file.fileURL) else {
            print("📱 [TELEMETRY] ❌ Failed to read file data")
            return
        }
        
        print("📱 [TELEMETRY] File size: \(data.count) bytes")
        
        guard let samples = try? decoder.decode([MotionSample].self, from: data) else {
            print("📱 [TELEMETRY] ❌ Failed to decode motion samples")
            return
        }
        
        print("📱 [TELEMETRY] ✅ Decoded \(samples.count) motion samples")
        
        // Notify coordinator on main thread
        DispatchQueue.main.async {
            print("📱 [TELEMETRY] Posting WatchDataReceived notification")
            NotificationCenter.default.post(
                name: NSNotification.Name("WatchDataReceived"),
                object: samples
            )
        }
    }
    
    // iOS-only delegate methods
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 Session deactivated, reactivating...")
        session.activate()
    }
    #endif
}
