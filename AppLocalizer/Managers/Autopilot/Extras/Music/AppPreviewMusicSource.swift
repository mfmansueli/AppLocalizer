//
//  AppPreviewMusicSource.swift
//  AppLocalizer
//

import Foundation

/// Where an App Preview's music comes from: a library track AppLocalizer
/// plays itself, or an audio file on this Mac.
enum AppPreviewMusicSource: Hashable, Sendable {
    case track(AppPreviewTrack)
    case file(URL)
}
