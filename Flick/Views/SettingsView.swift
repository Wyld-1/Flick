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
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $settings.isFlickDirectionReversed) {
                        Label("Reverse flick direction", systemImage: "arrow.left.arrow.right")
                            .foregroundStyle(.orange)
                    }
                    .tint(.orange)
                    
                    Toggle(isOn: $settings.isTapEnabled) {
                        Label("Tap Watch to play/pause", systemImage: "hand.tap.fill")
                            .foregroundStyle(.orange)
                    }
                    .tint(.orange)
                } header: {
                    Text("Gesture Controls")
                }
                
                Section {
                    Link(destination: URL(string: "https://github.com/Wyld-1/Coda")!) {
                        HStack {
                            Image(systemName: "hammer.circle.fill")
                            Text("Build Coda with us")
                            
                        }
                        .foregroundStyle(.purple)
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
                        saveAndDismiss()
                    }
                    .foregroundStyle(.orange)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func resetTutorial() {
        settings.isTutorialCompleted = false
        SharedSettings.save(settings)
        dismiss()
    }
    
    private func saveAndDismiss() {
        SharedSettings.save(settings)
        dismiss()
    }
}

#Preview {
    SettingsView()
}
