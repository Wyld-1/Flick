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
    
    private let mAppleMusicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var mIsConnecting = false
    
    private let SHORTCUT_NAMES = [
        "nextTrack": "FlickNext",
        "previousTrack": "FlickPrevious",
        "playPause": "FlickPlayPause"
    ]
    
    override private init() {
        super.init()
        print("📱 MediaManager initialized")
        if let token = Self.savedToken {
            appRemote.connectionParameters.accessToken = token
            print("🔑 Loaded saved Spotify token")
        }
    }
    
    // MARK: - Spotify Connection
    
    private static let SPOTIFY_TOKEN_KEY = "spotifyAccessToken"
    private static let CONNECTION_TIMEOUT: UInt64 = 800_000_000 // 0.8s
    
    func connectToSpotify() {
        guard !appRemote.isConnected, !mIsConnecting else { return }
        guard let token = Self.savedToken else {
            print("⚠️ No token - authorize first")
            return
        }
        
        appRemote.connectionParameters.accessToken = token
        mIsConnecting = true
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
        mIsConnecting = true
        appRemote.connect()
        print("✅ Token saved, connecting...")
    }
    
    func authorizeSpotify() async {
        guard !appRemote.isConnected, !mIsConnecting else { return }
        
        // Try existing token first
        if Self.savedToken != nil {
            connectToSpotify()
            try? await Task.sleep(nanoseconds: Self.CONNECTION_TIMEOUT)
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
        mIsConnecting = false
    }
    
    // MARK: - Token Management
    
    var hasValidToken: Bool {
        Self.savedToken != nil
    }
    
    private static var savedToken: String? {
        UserDefaults.standard.string(forKey: SPOTIFY_TOKEN_KEY)
    }
    
    private static func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: SPOTIFY_TOKEN_KEY)
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
        } else {
            // Reconnect if needed, then retry after a short delay
            if !mIsConnecting { connectToSpotify() }
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
            mAppleMusicPlayer.skipToNextItem()
        case .previousTrack:
            mAppleMusicPlayer.skipToPreviousItem()
        case .playPause:
            if mAppleMusicPlayer.playbackState == .playing {
                mAppleMusicPlayer.pause()
            } else {
                mAppleMusicPlayer.play()
            }
        }
    }
    
    private func handleCommandViaShortcuts(_ command: MediaCommand) {
        guard let shortcutName = SHORTCUT_NAMES[command.rawValue],
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
        mIsConnecting = false
        print("🟢 Spotify connected")
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: nil)
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        mIsConnecting = false
        print("🔴 Connection failed: \(error?.localizedDescription ?? "unknown")")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        mIsConnecting = false
        print("🔴 Disconnected")
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        // Silent - only log if needed for debugging
    }
}
