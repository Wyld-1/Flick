//
//  WatchReusableElements.swift
//  Flick Watch App
//
//  Shared utilities for the watch target.
//

import SwiftUI

// MARK: - Glass Compatibility Modifier

extension View {
    // Applies `.buttonStyle(.glass)` on watchOS 11+ (paired with iOS 26).
    // Falls back to a plain button style with a visible stroke overlay on
    // older watchOS versions so buttons remain clearly tappable.
    ///
    // Usage mirrors the iOS `flickGlass(in:)` pattern — call this *instead*
    // of `.buttonStyle(.glass)`, then keep `.buttonBorderShape()` and
    // `.controlSize()` as normal (they are still applied on both paths).
    @ViewBuilder
    func watchGlass() -> some View {
        if #available(watchOS 26, *) {
            self
                .buttonStyle(.glass)
        } else {
            self
                .buttonStyle(.plain)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 0.75)
                )
        }
    }
}
