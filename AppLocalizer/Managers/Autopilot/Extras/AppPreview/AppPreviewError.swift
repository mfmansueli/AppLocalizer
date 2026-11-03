//
//  AppPreviewError.swift
//  AppLocalizer
//

import Foundation

/// Why an App Preview couldn't be made, in a sentence the person can act
/// on.
enum AppPreviewError: LocalizedError, Equatable {
    /// The recording isn't a movie AppLocalizer can read.
    case unreadableRecording
    /// The recording has no video in it.
    case noVideoTrack
    /// No planned screen has a mark inside the recording.
    case noUsableMark
    /// Apple takes no App Preview for this device.
    case noSpec(ScreenshotDisplayType)
    /// Reading the recording stopped partway.
    case readerFailed(String)
    /// Writing the App Preview stopped partway.
    case writerFailed(String)
    /// A frame couldn't be drawn.
    case drawingFailed
    /// The person's music file isn't audio AppLocalizer can read.
    case unreadableMusic
    /// The person's music file has no sound in it.
    case silentMusic
    /// The plan uses the person's own file, and it isn't there.
    case noMusicFile

    var errorDescription: String? {
        switch self {
        case .unreadableMusic:
            String(localized: "The music file can't be read. Choose an .m4a, .mp3, .wav or .aiff file.")
        case .silentMusic:
            String(localized: "The music file has no sound in it. Choose another one.")
        case .noMusicFile:
            String(localized: "The App Preview’s music file is missing. Choose it again, or pick a track from AppLocalizer’s library.")
        case .unreadableRecording:
            String(localized: "The Simulator recording can't be read. Record it again.")
        case .noVideoTrack:
            String(localized: "The Simulator recording has no video in it. Record it again.")
        case .noUsableMark:
            String(localized: "None of the planned screens was marked inside the recording, so there's nothing to cut. Mark each screen as it shows up.")
        case let .noSpec(display):
            String(localized: "App Store Connect takes no App Preview for \(display.title).")
        case let .readerFailed(reason):
            String(localized: "Reading the Simulator recording stopped: \(reason)")
        case let .writerFailed(reason):
            String(localized: "Writing the App Preview stopped: \(reason)")
        case .drawingFailed:
            String(localized: "A frame of the App Preview couldn't be drawn.")
        }
    }
}
