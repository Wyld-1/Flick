//
//  SharedTypes.swift
//  Coda
//
//  Shared between iOS and watchOS targets
//

import Foundation

// Commands that can be sent from Watch to iPhone
enum MediaCommand: String, Codable {
    case nextTrack
    case previousTrack
    case playPause
}

// Settings that sync between devices
struct AppSettings: Codable {
    var isTapEnabled: Bool
    var isFlickDirectionReversed: Bool
}
