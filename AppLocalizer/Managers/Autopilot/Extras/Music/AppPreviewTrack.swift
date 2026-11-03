//
//  AppPreviewTrack.swift
//  AppLocalizer
//

import Foundation

/// The music under an App Preview: one of AppLocalizer's library tracks,
/// or the person's own file. Every App Preview has music; there's no
/// "None". Library tracks are made by AppLocalizer on this Mac
/// (`AppPreviewSynth`), so they're free to use on the App Store; with
/// their own file, the person confirms they hold the rights.
enum AppPreviewTrack: String, Codable, CaseIterable, Hashable, Sendable {
    case warmAcoustic = "warm_acoustic"
    case calmPiano = "calm_piano"
    case brightPop = "bright_pop"
    case ownFile = "own_file"

    /// AppLocalizer's library, in the order the plan shows it.
    static let library: [AppPreviewTrack] = [.warmAcoustic, .calmPiano, .brightPop]

    var isLibrary: Bool { self != .ownFile }

    /// "Warm acoustic".
    var title: String {
        switch self {
        case .warmAcoustic: String(localized: "Warm acoustic")
        case .calmPiano: String(localized: "Calm piano")
        case .brightPop: String(localized: "Bright pop")
        case .ownFile: String(localized: "Your file")
        }
    }

    /// For the assistant: what the track sounds like.
    var mood: String {
        switch self {
        case .warmAcoustic: "plucked guitar and soft bass, 92 bpm, warm and friendly"
        case .calmPiano: "slow piano chords, 70 bpm, quiet and calm"
        case .brightPop: "synth arpeggio, bass and light drums, 118 bpm, upbeat"
        case .ownFile: "the person's own file"
        }
    }
}
