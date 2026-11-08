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
    case softAmbient = "soft_ambient"
    case lofiBeat = "lofi_beat"
    case cinematicBuild = "cinematic_build"
    case playfulMarimba = "playful_marimba"
    case ownFile = "own_file"

    /// AppLocalizer's library, in the order the plan shows it.
    static let library: [AppPreviewTrack] = featured + more
    /// The tracks the plan shows side by side.
    static let featured: [AppPreviewTrack] = [.warmAcoustic, .calmPiano, .brightPop]
    /// The rest, in a menu.
    static let more: [AppPreviewTrack] = [.softAmbient, .lofiBeat, .cinematicBuild, .playfulMarimba]

    var isLibrary: Bool { self != .ownFile }

    /// "Warm acoustic".
    var title: String {
        switch self {
        case .warmAcoustic: String(localized: "Warm acoustic")
        case .calmPiano: String(localized: "Calm piano")
        case .brightPop: String(localized: "Bright pop")
        case .softAmbient: String(localized: "Soft ambient")
        case .lofiBeat: String(localized: "Lo-fi beat")
        case .cinematicBuild: String(localized: "Cinematic build")
        case .playfulMarimba: String(localized: "Playful marimba")
        case .ownFile: String(localized: "Your file")
        }
    }

    /// For the assistant: what the track sounds like.
    var mood: String {
        switch self {
        case .warmAcoustic: "plucked guitar and soft bass, 92 bpm, warm and friendly"
        case .calmPiano: "slow piano chords, 70 bpm, quiet and calm"
        case .brightPop: "synth arpeggio, bass and light drums, 118 bpm, upbeat"
        case .softAmbient: "long detuned pads, a low drone and sparse bells, 64 bpm, quiet, intimate and spacious"
        case .lofiBeat: "soft electric keys, round bass and a laid-back swung beat, 76 bpm, relaxed and modern"
        case .cinematicBuild: "strings swelling over a plucked pulse, low hits in the second half, 88 bpm, serious and inspiring"
        case .playfulMarimba: "bouncing marimba, plucked bass and light claps, 124 bpm, cheerful and light"
        case .ownFile: "the person's own file"
        }
    }
}
