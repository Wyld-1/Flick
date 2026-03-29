//
//  ShortcutsSetupView.swift
//  Flick
//
//  Created by Liam Lefohn on 2/6/26.
//

import SwiftUI

struct ShortcutsSetupView: View {
    @EnvironmentObject var appState: AppStateManager
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    
    // Data model
    struct InstructionRow: Identifiable {
        let id = UUID()
        let icon: String
        let text: LocalizedStringKey
    }
    
    struct SetupStep {
        let title: String
        let mainIcon: String
        let instructions: [InstructionRow]
        let actionTitle: String?
        let urlScheme: String?
        let isDownloadable: Bool
    }
    
    // Configuration
    let setupSteps = [
        // STEP 1: Friendly Intro
        SetupStep(
            title: "Quick Setup",
            mainIcon: "wand.and.stars",
            instructions: [
                InstructionRow(icon: "music.note", text: "Flick uses Apple Shortcuts to seamlessly control your audio."),
                InstructionRow(icon: "arrow.down.circle.fill", text: "We will import **3 small helpers** to get you connected."),
                InstructionRow(icon: "checkmark.circle.fill", text: "Simply tap **'Add Shortcut'** on the next few screens.")
            ],
            actionTitle: nil,
            urlScheme: nil,
            isDownloadable: false
        ),
        
        // STEP 2: FlickNext
        SetupStep(
            title: "FlickNext",
            mainIcon: "forward.fill",
            instructions: [
                InstructionRow(icon: "plus.circle.fill", text: "Tap **+** to create a new shortcut"),
                InstructionRow(icon: "forward.fill", text: "Add the **'Skip Forward'** action"),
                InstructionRow(icon: "text.cursor", text: "Rename to: **FlickNext**")
            ],
            actionTitle: "Add Shortcut",
            urlScheme: "https://www.icloud.com/shortcuts/9bd9c6bf8ff141c4a62edc6c30a6db71",
            isDownloadable: true
        ),
        
        // STEP 3: FlickPrevious
        SetupStep(
            title: "FlickPrevious",
            mainIcon: "backward.fill",
            instructions: [
                InstructionRow(icon: "plus.circle.fill", text: "Tap **+** to create a new shortcut"),
                InstructionRow(icon: "backward.fill", text: "Add the **'Skip Back'** action"),
                InstructionRow(icon: "text.cursor", text: "Rename to: **FlickPrevious**")
            ],
            actionTitle: "Add Shortcut",
            urlScheme: "https://www.icloud.com/shortcuts/6ee63669f3b04e2f94bb5a143cde57a2",
            isDownloadable: true
        ),
        
        // STEP 4: FlickPlayPause
        SetupStep(
            title: "FlickPlayPause",
            mainIcon: "playpause.fill",
            instructions: [
                InstructionRow(icon: "plus.circle.fill", text: "Tap **+** to create a new shortcut"),
                InstructionRow(icon: "playpause.fill", text: "Add the **'Play/Pause'** action"),
                InstructionRow(icon: "text.cursor", text: "Rename to: **FlickPlayPause**")
            ],
            actionTitle: "Add Shortcut",
            urlScheme: "https://www.icloud.com/shortcuts/56b8737e5cb9404ebf38e0baf9b0042b",
            isDownloadable: true
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [.orange.opacity(0.1), .clear]),
                center: .top,
                startRadius: 10,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header and navigation dots
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(0..<setupSteps.count, id: \.self) { index in
                            Circle()
                                .fill(currentStep == index ? Color.orange : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                                .animation(.spring, value: currentStep)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Content Carousel
                TabView(selection: $currentStep) {
                    ForEach(0..<setupSteps.count, id: \.self) { index in
                        StepCardView(step: setupSteps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom Navigation
                Button(action: {
                    HapticManager.shared.playImpact()
                    handleNextButton()
                }) {
                    Text(isLastStep ? "Finish Setup" : "Next Step")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.black)
                        .frame(height: 45)
                }
                .padding(.horizontal, 30)
                .tint(.orange)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func handleNextButton() {
        HapticManager.shared.playImpact()
        
        if isLastStep {
            UserDefaults.standard.set(true, forKey: "shortcutsConfigured")
            var settings = SharedSettings.load()
            settings.hasCompletedInitialSetup = true;
            dismiss()
        } else {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    var isLastStep: Bool {
        currentStep == setupSteps.count - 1
    }
}

// MARK: - Views

struct StepCardView: View {
    let step: ShortcutsSetupView.SetupStep
    @State private var isManualExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- HEADER ZONE ---
            // Pins the icon and title to the top of the screen
            VStack(spacing: 0) {
                Spacer().frame(height: 20) // Top Margin
                
                // Icon Container
                ZStack {
                    if step.mainIcon == "Shortcuts Icon" {
                        Image(step.mainIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 4)
                    } else {
                        Image(systemName: step.mainIcon)
                            .font(.system(size: 80))
                            .foregroundStyle(.orange)
                            .symbolEffect(.bounce, value: step.mainIcon)
                    }
                }
                .frame(height: 100) // Fixed height for icon area
                .padding(.bottom, 20)
                
                // Title Container
                Text(step.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(height: 45)
            }
            .padding(.bottom, 30)
            
            // Content
            if step.isDownloadable {
                VStack(spacing: 0) {
                    
                    VStack(spacing: 0) {
                        
                        // Primary Action: Add Shortcut Link
                        if let action = step.actionTitle, let urlString = step.urlScheme, let url = URL(string: urlString) {
                            Button(action: {
                                UIApplication.shared.open(url)
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "icloud.and.arrow.down")
                                        .font(.title3)
                                    Text(action)
                                        .font(.headline)
                                        .bold()
                                }
                                .frame(maxWidth: .infinity, minHeight: 45)
                                .foregroundStyle(.black)
                            }
                            .tint(.orange)
                            .buttonStyle(.glassProminent)
                            .buttonBorderShape(.capsule)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.horizontal, 20)
                        
                        // Manual Fallback Toggle
                        VStack(spacing: 0) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isManualExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Text("Or set up manually")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                        .rotationEffect(.degrees(isManualExpanded ? 90 : 0))
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                                .contentShape(Rectangle())
                            }
                            
                            if isManualExpanded {
                                InstructionsListView(instructions: step.instructions)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
                
            } else {
                // STANDARD LAYOUT (Step 1 - Intro)
                // Just the instructions list, aligned to top
                InstructionsListView(instructions: step.instructions)
                    .padding(.horizontal, 24)
            }
            
            // --- FLEXIBLE ZONE ---
            // This Spacer absorbs all extra space.
            // Expanding the menu eats THIS space, so the Header stays pinned.
            Spacer()
        }
    }
}

// Subview for the list of instructions
struct InstructionsListView: View {
    let instructions: [ShortcutsSetupView.InstructionRow]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(instructions) { instruction in
                HStack(spacing: 16) {
                    Image(systemName: instruction.icon)
                        .font(.system(size: 20))
                        .frame(width: 30)
                        .foregroundStyle(.orange)
                    
                    Text(instruction.text)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    ShortcutsSetupView()
        .environmentObject(AppStateManager())
}
