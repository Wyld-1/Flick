//
//  iOSMediaManager.swift
//  Flick
//
//  Handles media playback on iPhone via Apple Music, Spotify Web API, or Shortcuts.
//

import Foundation
import MediaPlayer
import UIKit
import AuthenticationServices
import CommonCrypto
import Combine

#if DEBUG
import AudioToolbox
#endif

class iOSMediaManager: NSObject, ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    static let shared = iOSMediaManager()

    // MARK: - Spotify Web API Configuration
    //
    // Scopes required in Spotify Developer Dashboard:
    //   user-modify-playback-state  (skip, play, pause)
    //   user-read-playback-state    (read isPaused for play/pause toggle)

    private let SPOTIFY_CLIENT_ID    = "9dbd8137ece84ceabd0c91b52f0ae5f9"
    private let SPOTIFY_REDIRECT_URI = "flick://callback"
    private let SPOTIFY_SCOPES       = "user-modify-playback-state user-read-playback-state"

    // Keychain keys
    private let ACCESS_TOKEN_KEY  = "spotify_access_token"
    private let REFRESH_TOKEN_KEY = "spotify_refresh_token"
    private let TOKEN_EXPIRY_KEY  = "spotify_token_expiry"   // stored in UserDefaults (not sensitive)

    // Spotify Web API base URL
    private let SPOTIFY_API_BASE = "https://api.spotify.com/v1"

    // MARK: - Apple Music
    private let mAppleMusicPlayer = MPMusicPlayerController.systemMusicPlayer

    // MARK: - Shortcuts
    private let SHORTCUT_NAMES = [
        "nextTrack":     "FlickNext",
        "previousTrack": "FlickPrevious",
        "playPause":     "FlickPlayPause"
    ]

    // MARK: - State
    // PKCE code verifier kept in memory during the auth flow
    private var mPKCEVerifier: String?
    // Auth session reference kept alive for its duration
    private var mAuthSession: ASWebAuthenticationSession?
    // Tracks an in-flight token refresh so we don't double-refresh
    private var mRefreshTask: Task<String?, Never>?

    private override init() {
        super.init()
        print("📱 MediaManager initialized")
    }

    // MARK: - Public Auth Interface

    // True when we have a stored refresh token (i.e. user has authenticated at least once).
    var hasValidToken: Bool {
        loadFromKeychain(key: REFRESH_TOKEN_KEY) != nil
    }

    // Launches the Spotify OAuth PKCE flow in an ASWebAuthenticationSession.
    // Resolves when the user completes or cancels the flow.
    @MainActor
    func authorizeSpotify() async {
        // Build PKCE pair
        let verifier  = PKCE.generateVerifier()
        let challenge = PKCE.generateChallenge(from: verifier)
        mPKCEVerifier = verifier

        // Build authorization URL
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            .init(name: "client_id",             value: SPOTIFY_CLIENT_ID),
            .init(name: "response_type",         value: "code"),
            .init(name: "redirect_uri",           value: SPOTIFY_REDIRECT_URI),
            .init(name: "scope",                  value: SPOTIFY_SCOPES),
            .init(name: "code_challenge_method",  value: "S256"),
            .init(name: "code_challenge",         value: challenge),
        ]
        guard let authURL = components.url else { return }

        // Present the browser login sheet
        await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "flick"
            ) { [weak self] callbackURL, error in
                guard let self else { continuation.resume(); return }
                if let error {
                    print("🔴 Spotify auth cancelled or failed: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }
                Task {
                    await self.handleAuthCallback(callbackURL)
                    continuation.resume()
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            mAuthSession = session
            session.start()
        }
    }

    // Called from FlickApp.onOpenURL when Spotify redirects back.
    func handleSpotifyURL(_ url: URL) {
        Task { await handleAuthCallback(url) }
    }

    // MARK: - Command Handler

    func handleCommand(_ command: MediaCommand) {
        #if DEBUG
        AudioServicesPlaySystemSound(1520)
        #endif

        let settings = SharedSettings.load()
        switch settings.playbackMethod {
        case .spotify:    Task { await handleCommandViaSpotify(command) }
        case .appleMusic: handleCommandViaAppleMusic(command)
        case .shortcuts:  handleCommandViaShortcuts(command)
        }

        NotificationCenter.default.post(name: NSNotification.Name("CommandReceived"), object: command)
    }

    // MARK: - Spotify Web API Playback

    private func handleCommandViaSpotify(_ command: MediaCommand) async {
        guard let token = await validAccessToken() else {
            print("🔴 No valid Spotify token — user needs to re-authorize")
            await MainActor.run { HapticManager.shared.playWarning() }
            return
        }

        switch command {
        case .nextTrack:
            await spotifyRequest(method: "POST", path: "/me/player/next", token: token)
        case .previousTrack:
            await spotifyRequest(method: "POST", path: "/me/player/previous", token: token)
        case .playPause:
            await spotifyTogglePlayPause(token: token)
        }
    }

    private func spotifyTogglePlayPause(token: String) async {
        // Fetch current playback state, then play or pause accordingly
        guard let url = URL(string: "\(SPOTIFY_API_BASE)/me/player") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let isPlaying = json["is_playing"] as? Bool else {
            // If we can't read state, just send play — safe default
            await spotifyRequest(method: "PUT", path: "/me/player/play", token: token)
            return
        }

        let path = isPlaying ? "/me/player/pause" : "/me/player/play"
        await spotifyRequest(method: "PUT", path: path, token: token)
    }

    // Fires a Spotify Web API request. 204 No Content is the success response for player endpoints.
    @discardableResult
    private func spotifyRequest(method: String, path: String, token: String) async -> Bool {
        guard let url = URL(string: "\(SPOTIFY_API_BASE)\(path)") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status == 204 || status == 200 {
                print("✅ Spotify \(method) \(path) → \(status)")
                return true
            } else {
                print("⚠️ Spotify \(method) \(path) → \(status)")
                await MainActor.run { HapticManager.shared.playWarning() }
                return false
            }
        } catch {
            print("🔴 Spotify request error: \(error.localizedDescription)")
            await MainActor.run { HapticManager.shared.playWarning() }
            return false
        }
    }

    // MARK: - Token Lifecycle

    // Returns a valid access token, refreshing silently if it has expired.
    private func validAccessToken() async -> String? {
        // If a refresh is already in flight, wait for it
        if let existing = mRefreshTask {
            return await existing.value
        }

        // Check expiry — give 60s buffer so we never send an about-to-expire token
        let expiry = UserDefaults.standard.double(forKey: TOKEN_EXPIRY_KEY)
        let isExpired = expiry == 0 || Date().timeIntervalSince1970 > expiry - 60

        if !isExpired, let token = loadFromKeychain(key: ACCESS_TOKEN_KEY) {
            return token
        }

        // Token expired — refresh silently
        guard loadFromKeychain(key: REFRESH_TOKEN_KEY) != nil else {
            print("⚠️ No refresh token — user must re-authorize")
            return nil
        }

        let task = Task<String?, Never> { await self.performTokenRefresh() }
        mRefreshTask = task
        let result = await task.value
        mRefreshTask = nil
        return result
    }

    // Exchanges the stored refresh token for a new access token.
    private func performTokenRefresh() async -> String? {
        guard let refreshToken = loadFromKeychain(key: REFRESH_TOKEN_KEY) else { return nil }

        var components = URLComponents(string: "https://accounts.spotify.com/api/token")!
        components.queryItems = [
            .init(name: "grant_type",    value: "refresh_token"),
            .init(name: "refresh_token", value: refreshToken),
            .init(name: "client_id",     value: SPOTIFY_CLIENT_ID),
        ]

        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let expiresIn = json["expires_in"] as? TimeInterval else {
            print("🔴 Token refresh failed")
            return nil
        }

        saveToKeychain(key: ACCESS_TOKEN_KEY, value: accessToken)
        // Spotify may rotate the refresh token; save if provided
        if let newRefresh = json["refresh_token"] as? String {
            saveToKeychain(key: REFRESH_TOKEN_KEY, value: newRefresh)
        }
        UserDefaults.standard.set(Date().timeIntervalSince1970 + expiresIn, forKey: TOKEN_EXPIRY_KEY)

        print("🔑 Access token refreshed (expires in \(Int(expiresIn))s)")
        return accessToken
    }

    // MARK: - Auth Callback

    private func handleAuthCallback(_ url: URL?) async {
        guard let url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let verifier = mPKCEVerifier else {
            print("🔴 Invalid auth callback")
            return
        }
        mPKCEVerifier = nil

        // Exchange authorization code for tokens
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            .init(name: "grant_type",    value: "authorization_code"),
            .init(name: "code",           value: code),
            .init(name: "redirect_uri",   value: SPOTIFY_REDIRECT_URI),
            .init(name: "client_id",     value: SPOTIFY_CLIENT_ID),
            .init(name: "code_verifier", value: verifier),
        ]
        request.httpBody = bodyComponents.percentEncodedQuery?.data(using: .utf8)

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken  = json["access_token"]  as? String,
              let refreshToken = json["refresh_token"] as? String,
              let expiresIn    = json["expires_in"]    as? TimeInterval else {
            print("🔴 Token exchange failed")
            return
        }

        saveToKeychain(key: ACCESS_TOKEN_KEY,  value: accessToken)
        saveToKeychain(key: REFRESH_TOKEN_KEY, value: refreshToken)
        UserDefaults.standard.set(Date().timeIntervalSince1970 + expiresIn, forKey: TOKEN_EXPIRY_KEY)

        print("✅ Spotify authorized. Token expires in \(Int(expiresIn))s")
    }

    // MARK: - Apple Music

    private func handleCommandViaAppleMusic(_ command: MediaCommand) {
        switch command {
        case .nextTrack:     mAppleMusicPlayer.skipToNextItem()
        case .previousTrack: mAppleMusicPlayer.skipToPreviousItem()
        case .playPause:
            if mAppleMusicPlayer.playbackState == .playing {
                mAppleMusicPlayer.pause()
            } else {
                mAppleMusicPlayer.play()
            }
        }
    }

    // MARK: - Shortcuts

    private func handleCommandViaShortcuts(_ command: MediaCommand) {
        guard let shortcutName = SHORTCUT_NAMES[command.rawValue],
              let encoded = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://run-shortcut?name=\(encoded)") else { return }
        UIApplication.shared.open(url) { success in
            if !success { DispatchQueue.main.async { HapticManager.shared.playWarning() } }
        }
    }

    // MARK: - Keychain Helpers

    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrAccount:     key,
            kSecAttrService:     "com.flickplayback.tokens",
            kSecValueData:       data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrAccount:     key,
            kSecAttrService:     "com.flickplayback.tokens",
            kSecReturnData:      true,
            kSecMatchLimit:      kSecMatchLimitOne,
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension iOSMediaManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

// MARK: - PKCE Helpers

private enum PKCE {
    static func generateVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func generateChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest) }
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
