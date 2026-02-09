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
    
    // Data model for the specific instruction rows
    struct InstructionRow: Identifiable {
        let id = UUID()
        let icon: String
        let text: LocalizedStringKey // Use Key for Markdown support
    }
    
    // Steps Configuration
    let setupSteps = [
        SetupStep(
            title: "Open Shortcuts",
            mainIcon: "Shortcuts Icon",
            instructions: [
                InstructionRow(icon: "iphone", text: "Go to your Home Screen"),
                InstructionRow(icon: "magnifyingglass", text: "Find and open the **Shortcuts** app")
            ],
            actionTitle: "Launch Shortcuts",
            urlScheme: "shortcuts://"
        ),
        SetupStep(
            title: "FlickNext",
            mainIcon: "forward.fill",
            instructions: [
                InstructionRow(icon: "plus.circle.fill", text: "Tap **+** to create a new shortcut"),
                InstructionRow(icon: "forward.fill", text: "Add the **'Skip Forward'** action"),
                InstructionRow(icon: "text.cursor", text: "Rename to: **FlickNext**")
            ],
            actionTitle: nil,
            urlScheme: nil
        ),
        SetupStep(
            title: "FlickPrevious",
            mainIcon: "backward.fill",
            instructions: [
                InstructionRow(icon: "plus.circle.fill", text: "Create another new shortcut"),
                InstructionRow(icon: "backward.fill", text: "Add the **'Skip Back'** action"),
                InstructionRow(icon: "text.cursor", text: "Rename to: **FlickPrevious**")
            ],
            actionTitle: nil,
            urlScheme: nil
        ),
        SetupStep(
            title: "FlickPlayPause",
            mainIcon: "playpause.fill",
            instructions: [
                InstructionRow(icon: "plus.circle.fill", text: "Create the final shortcut"),
                InstructionRow(icon: "playpause.fill", text: "Add the **'Play/Pause'** action"),
                InstructionRow(icon: "text.cursor", text: "Rename to: **FlickPlayPause**")
            ],
            actionTitle: nil,
            urlScheme: nil
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [.orange.opacity(0.1), .clear]),
                center: .center,
                startRadius: 10,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    
                    // Dots
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
                .padding()
                
                // Carousel
                TabView(selection: $currentStep) {
                    ForEach(0..<setupSteps.count, id: \.self) { index in
                        StepCardView(step: setupSteps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Main Action Button
                VStack {
                    Button(action: {
                        if isLastStep && appState.currentState != .main {
                            appState.completePlaybackChoice(useShortcuts: true)
                        }
                        
                        handleNextButton()
                    }) {
                        Text(isLastStep ? "Finish Setup" : "Next Step")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(VividGlassButtonStyle()) // Uses shared style
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func handleNextButton() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if isLastStep {
            UserDefaults.standard.set(true, forKey: "shortcutsConfigured")
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
    let step: SetupStep
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon Logic: Check if it's the Asset Name or a System Symbol
            if step.mainIcon == "Shortcuts Icon" {
                Image(step.mainIcon) // Loads your custom Asset
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18)) // iOS App Icon Shape
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 4)
                    .padding(.bottom, 10)
            } else {
                Image(systemName: step.mainIcon)
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, value: step.mainIcon)
                    .padding(.bottom, 10)
            }
            
            // Title
            Text(step.title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            // Instruction List
            VStack(alignment: .leading, spacing: 12) {
                ForEach(step.instructions) { instruction in
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
            .padding(.horizontal, 24)
            
            // Launch button (only for Step 1)
            if let action = step.actionTitle,
               let urlString = step.urlScheme,
               let url = URL(string: urlString) {
                
                Button(action: {
                    UIApplication.shared.open(url)
                }) {
                    HStack {
                        Text(action)
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
                }
                .padding(.top, 10)
            }
            
            Spacer()
            Spacer()
        }
    }
}

struct SetupStep {
    let title: String
    let mainIcon: String
    let instructions: [ShortcutsSetupView.InstructionRow]
    let actionTitle: String?
    let urlScheme: String?
}

#Preview {
    ShortcutsSetupView()
        .environmentObject(AppStateManager())
}
