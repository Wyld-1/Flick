//
//  SettingsView.swift
//  Coda
//
//  Created by Liam Lefohn on 2/5/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var settings = SharedSettings.load()
    @State private var showShortcutsSetup = false
    @State private var showTestControls = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: Binding(
                        get: { settings.isFlickDirectionReversed },
                        set: { newValue in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            settings.isFlickDirectionReversed = newValue
                            saveSettings()
                        }
                    )) {
                        HStack(spacing: 15) {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundStyle(.orange)
                            Text("Reverse flick direction")
                        }
                    }
                    .tint(.orange)
                    
                    Toggle(isOn: Binding(
                        get: { settings.isTapEnabled },
                        set: { newValue in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            settings.isTapEnabled = newValue
                            saveSettings()
                        }
                    )) {
                        HStack(spacing: 15) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundStyle(.orange)
                            Text("Tap Watch to play/pause")
                        }
                    }
                    .tint(.orange)
                } header: {
                    Text("Gesture Controls")
                }
                
                Section {
                    Toggle(isOn: Binding(
                        get: { settings.useShortcutsForPlayback },
                        set: { newValue in
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            settings.useShortcutsForPlayback = newValue
                            saveSettings()
                        }
                    )) {
                        HStack(spacing: 15) {
                            Image(systemName: "music.note")
                                .foregroundStyle(.white)
                            Text("Shortcuts Playback Mode")
                                .foregroundStyle(.white)
                        }
                    
                    }
                    .tint(.orange)
                    
                    if settings.useShortcutsForPlayback {
                        Button(action: {
                            triggerHaptic()
                            showShortcutsSetup = true
                        }) {
                            HStack {
                                Image(systemName: "book.circle.fill")
                                    .foregroundStyle(.white)
                                Text("Configure Shortcuts")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.gray)
                            }
                            .foregroundStyle(.white)
                        }
                        
                        Link(destination: URL(string: "shortcuts://")!) {
                            HStack {
                                Image("Shortcuts Icon")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                Text("Open Shortcuts App")
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "arrow.up.forward")
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                } header: {
                    Text("Playback Method")
                } footer: {
                    if settings.useShortcutsForPlayback {
                        Text("Shortcuts require iPhone to be unlocked. Disable to use Apple Music API.")
                    } else {
                        Text("Using Apple Music API. Enable Shortcuts Mode for universal compatibility.")
                    }
                }
                
                Section {
                    Button(action: {
                        triggerHaptic()
                        showTestControls = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "flask.fill")
                                .foregroundStyle(.purple)
                            Text("Open test panel")
                                .foregroundStyle(.white)
                        }
                    }
                } header: {
                    Text ("Debug Features")
                }
                
                Section {
                    Link(destination: URL(string: "https://github.com/Wyld-1/Coda")!) {
                        HStack {
                            Image(systemName: "hammer.circle.fill")
                                .foregroundStyle(.purple)
                            Text("Build Coda with us")
                                .foregroundStyle(.white)
                        }
                    }
                } header: {
                    Text("Contribute")
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/Wyld-1/Coda")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.white)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        triggerHaptic()
                        saveAndDismiss()
                    }
                    .foregroundStyle(.orange)
                }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showShortcutsSetup) {
            ShortcutsSetupView()
        }
        
        .sheet (isPresented: $showTestControls) {
            TestView()
        }
    }
    
    private func saveAndDismiss() {
        SharedSettings.save(settings)
        dismiss()
    }
    
    private func saveSettings() {
        SharedSettings.save(settings)
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    SettingsView()
}
