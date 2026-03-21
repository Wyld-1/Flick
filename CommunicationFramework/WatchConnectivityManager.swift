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
    
    private var mCommandQueue: [MediaCommand] = []
    private var mRetryTimer: Timer?
    private var mProgressObserver: NSKeyValueObservation?
    
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
        // Cap queue at 3 to prevent unbounded growth
        if mCommandQueue.count > 3 {
            mCommandQueue.removeFirst()
        }
        mCommandQueue.append(command)
        startRetryTimer()
    }
    
    private func startRetryTimer() {
        guard mRetryTimer == nil else { return }
        mRetryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.retryQueuedCommands()
        }
    }
    
    private func retryQueuedCommands() {
        guard !mCommandQueue.isEmpty, WCSession.default.isReachable else { return }
        let commands = mCommandQueue
        mCommandQueue.removeAll()
        for command in commands {
            sendMediaCommand(command)
        }
    }
    
    private func clearRetryTimer() {
        mRetryTimer?.invalidate()
        mRetryTimer = nil
        mCommandQueue.removeAll()
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
        guard WCSession.default.activationState == .activated else {
            print("⌚️ Cannot send file - session not activated")
            return
        }
        
        let metadata = ["type": "motionData", "filename": fileURL.lastPathComponent]
        let transfer = WCSession.default.transferFile(fileURL, metadata: metadata)
        print("⌚️ File transfer initiated - isTransferring: \(transfer.isTransferring)")
        
        mProgressObserver = transfer.progress.observe(\.fractionCompleted, options: [.new]) { progress, _ in
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("FileTransferProgress"),
                    object: progress.fractionCompleted
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
            if session.isReachable {
                self.retryQueuedCommands()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        replyHandler(["status": "received"])
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
    
    // MARK: - Receive Application Context (Both sides)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        guard let settingsData = applicationContext["settings"] as? Data else {
            print("❌ No settings data in context")
            return
        }
        
        do {
            let receivedSettings = try JSONDecoder().decode(AppSettings.self, from: settingsData)
            
            // Persist to App Group so both targets read the same source
            if let defaults = UserDefaults(suiteName: "group.flickplayback.SharedFiles") {
                let encoded = try JSONEncoder().encode(receivedSettings)
                defaults.set(encoded, forKey: "appSettings")
                defaults.synchronize()
            }
            
            #if os(iOS)
            print("✅ Settings synced from Watch - tutorial: \(receivedSettings.isTutorialCompleted), setup: \(receivedSettings.hasCompletedInitialSetup)")
            #else
            print("✅ Settings synced from iPhone - method: \(receivedSettings.playbackMethod)")
            #endif
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("SettingsDidUpdate"), object: nil)
            }
        } catch {
            print("❌ Failed to decode settings: \(error)")
        }
    }
    
    // MARK: - Receive File Transfer (iPhone)
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("📱 iPhone received file: \(file.fileURL.lastPathComponent)")
        
        guard let type = file.metadata?["type"] as? String, type == "motionData" else {
            print("📱 Unknown file type in metadata")
            return
        }
        
        guard let data = try? Data(contentsOf: file.fileURL) else {
            print("📱 Failed to read file data")
            return
        }
        
        guard let samples = try? JSONDecoder().decode([MotionSample].self, from: data) else {
            print("📱 Failed to decode motion samples")
            return
        }
        
        print("📱 Decoded \(samples.count) motion samples")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("WatchDataReceived"),
                object: samples
            )
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
