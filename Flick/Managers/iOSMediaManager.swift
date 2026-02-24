//
//  iOSMediaManager.swift
//  Flick
//
//  Handles media playback on iPhone
//

import Foundation
import MediaPlayer
import UIKit
import Combine

#if DEBUG
import AudioToolbox
#endif

class iOSMediaManager: NSObject, ObservableObject, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    
    static let shared = iOSMediaManager()
    
    // MARK: - Spotify Configuration
    let spotifyClientID = "9dbd8137ece84ceabd0c91b52f0ae5f9"
    let spotifyRedirectURL = URL(string: "flick://callback")!
    
    lazy var configuration = SPTConfiguration(clientID: spotifyClientID, redirectURL: spotifyRedirectURL)
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()
    
    private let appleMusicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var isConnecting = false
    
    // Shortcut names
    private let shortcutNames = [
        "nextTrack": "FlickNext",
        "previousTrack": "FlickPrevious",
        "playPause": "FlickPlayPause"
    ]
    
    override private init() {
        super.init()
        print("📱 MediaManager initialized")
        
        // Auto-load saved token
        if let token = Self.savedToken {
            appRemote.connectionParameters.accessToken = token
            print("🔑 Loaded saved Spotify token")
        }
    }
    
    // MARK: - Spotify Connection
    
    private static let spotifyTokenKey = "spotifyAccessToken"
    private static let connectionTimeout: UInt64 = 800_000_000 // 0.8s
    
    func connectToSpotify() {
        guard !appRemote.isConnected, !isConnecting else { return }
        guard let token = Self.savedToken else {
            print("⚠️ No token - authorize first")
            return
        }
        
        appRemote.connectionParameters.accessToken = token
        isConnecting = true
        appRemote.connect()
        print("🔗 Connecting to Spotify...")
    }
    
    func handleSpotifyURL(_ url: URL) {
        guard let params = appRemote.authorizationParameters(from: url),
              let token = params[SPTAppRemoteAccessTokenKey] else {
            print("❌ Invalid auth callback")
            return
        }
        
        Self.saveToken(token)
        appRemote.connectionParameters.accessToken = token
        isConnecting = true
        appRemote.connect()
        print("✅ Token saved, connecting...")
    }
    
    func authorizeSpotify() async {
        guard !appRemote.isConnected, !isConnecting else { return }
        
        // Try existing token first
        if Self.savedToken != nil {
            connectToSpotify()
            try? await Task.sleep(nanoseconds: Self.connectionTimeout)
            if appRemote.isConnected { return }
        }
        
        // Launch Spotify auth
        await MainActor.run {
            guard let url = URL(string: "spotify://"),
                  UIApplication.shared.canOpenURL(url) else {
                print("❌ Spotify not installed")
                HapticManager.shared.playWarning()
                return
            }
            appRemote.authorizeAndPlayURI("")
            print("🚀 Launching Spotify auth...")
        }
    }
    
    func disconnectFromSpotify() {
        if appRemote.isConnected { appRemote.disconnect() }
        isConnecting = false
    }
    
    // MARK: - Token Management
    
    var hasValidToken: Bool {
        Self.savedToken != nil
    }
    
    private static var savedToken: String? {
        UserDefaults.standard.string(forKey: spotifyTokenKey)
    }
    
    private static func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: spotifyTokenKey)
    }
    
    // MARK: - Command Handler
    
    func handleCommand(_ command: MediaCommand) {
        #if DEBUG
        AudioServicesPlaySystemSound(1520)
        #endif
        
        let settings = SharedSettings.load()
        
        switch settings.playbackMethod {
        case .spotify:
            executeSpotifyCommand(command)
        case .shortcuts:
            handleCommandViaShortcuts(command)
        case .appleMusic:
            handleCommandViaAppleMusic(command)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("CommandReceived"), object: command)
    }
    
    private func executeSpotifyCommand(_ command: MediaCommand) {
        if appRemote.isConnected {
            handleCommandViaSpotify(command)
        } else if isConnecting {
            // Queue command while connecting
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self, self.appRemote.isConnected else {
                    HapticManager.shared.playWarning()
                    return
                }
                self.handleCommandViaSpotify(command)
            }
        } else {
            // Attempt reconnect and queue
            connectToSpotify()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self, self.appRemote.isConnected else {
                    HapticManager.shared.playWarning()
                    return
                }
                self.handleCommandViaSpotify(command)
            }
        }
    }
    
    // MARK: - Playback Methods
    
    private func handleCommandViaSpotify(_ command: MediaCommand) {
        guard let playerAPI = appRemote.playerAPI else {
            print("❌ PlayerAPI not ready")
            return
        }
        
        switch command {
        case .nextTrack:
            playerAPI.skip(toNext: nil)
        case .previousTrack:
            playerAPI.skip(toPrevious: nil)
        case .playPause:
            playerAPI.getPlayerState { [weak self] result, _ in
                guard let state = result as? SPTAppRemotePlayerState else { return }
                if state.isPaused {
                    self?.appRemote.playerAPI?.resume(nil)
                } else {
                    self?.appRemote.playerAPI?.pause(nil)
                }
            }
        }
    }
    
    private func handleCommandViaAppleMusic(_ command: MediaCommand) {
        switch command {
        case .nextTrack:
            appleMusicPlayer.skipToNextItem()
        case .previousTrack:
            appleMusicPlayer.skipToPreviousItem()
        case .playPause:
            if appleMusicPlayer.playbackState == .playing {
                appleMusicPlayer.pause()
            } else {
                appleMusicPlayer.play()
            }
        }
    }
    
    private func handleCommandViaShortcuts(_ command: MediaCommand) {
        guard let shortcutName = shortcutNames[command.rawValue],
              let encoded = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://run-shortcut?name=\(encoded)") else {
            return
        }
        
        UIApplication.shared.open(url) { success in
            if !success {
                DispatchQueue.main.async { HapticManager.shared.playWarning() }
            }
        }
    }
    
    // MARK: - Spotify Delegates
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        isConnecting = false
        print("🟢 Spotify connected")
        
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: nil)
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        isConnecting = false
        print("🔴 Connection failed: \(error?.localizedDescription ?? "unknown")")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        isConnecting = false
        print("🔴 Disconnected")
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        // Silent - only log if needed for debugging
    }
}
