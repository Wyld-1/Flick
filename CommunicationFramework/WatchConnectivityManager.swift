//
//  WatchConnectivityManager.swift
//  Coda
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
            #endif
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
