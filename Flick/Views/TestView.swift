//
//  TestView.swift
//  Flick
//
//  Created by Liam Lefohn on 2/6/26.
//

import SwiftUI
import MediaPlayer

struct TestView: View {
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private let mediaManager = iOSMediaManager.shared
    
    @State private var isPlaying = false
    @State private var settings = SharedSettings.load()
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Mode indicator
                HStack(spacing: 8) {
                    Image(systemName: settings.useShortcutsForPlayback ? "music.note.square.stack.fill" : "music.note")
                        .font(.caption)
                    Text(settings.useShortcutsForPlayback ? "Shortcuts Mode" : "Apple API Mode")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)
                .padding(.top, 20)
                
                // Controls
                HStack(spacing: 60) {
                    Button(action: {
                        mediaManager.handleCommand(.previousTrack)
                        triggerHaptic()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 40))
                    }
                    
                    Button(action: {
                        mediaManager.handleCommand(.playPause)
                        triggerHaptic()
                        // Only update state if using Apple Music API
                        if !settings.useShortcutsForPlayback {
                            togglePlaybackState()
                        }
                    }) {
                        Image(systemName: playPauseIcon)
                            .font(.system(size: 55))
                            .frame(width: 80, height: 80)
                    }
                    
                    Button(action: {
                        mediaManager.handleCommand(.nextTrack)
                        triggerHaptic()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 40))
                    }
                }
                .foregroundStyle(.primary)
                .buttonStyle(.scaleEffect) // Uses shared extension
            }
        }
        .presentationDetents([.fraction(0.25)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(35)
        .onAppear {
            settings = SharedSettings.load()
            updatePlaybackState()
        }
        .onChange(of: settings.useShortcutsForPlayback) { _, _ in
            updatePlaybackState()
        }
    }
    
    // Show play/pause icon based on mode
    private var playPauseIcon: String {
        if settings.useShortcutsForPlayback {
            // Shortcuts mode - can't query state, show generic icon
            return "playpause.fill"
        } else {
            // Apple Music API - show actual state
            return isPlaying ? "pause.fill" : "play.fill"
        }
    }
    
    private func updatePlaybackState() {
        if !settings.useShortcutsForPlayback {
            isPlaying = musicPlayer.playbackState == .playing
        }
    }
    
    private func togglePlaybackState() {
        isPlaying.toggle()
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        Text("Background App Content")
            .foregroundStyle(.gray)
    }
    .sheet(isPresented: .constant(true)) {
        TestView()
    }
}
