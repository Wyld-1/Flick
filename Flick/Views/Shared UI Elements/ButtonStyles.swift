//
//  ButtonStyles.swift
//  Flick
//
//  Shared button styles
//

import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct VividGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(Color.orange)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.5), location: 0),
                                .init(color: .white.opacity(0.0), location: 0.5),
                                .init(color: .white.opacity(0.2), location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scaleEffect: ScaleButtonStyle { ScaleButtonStyle() }
}

