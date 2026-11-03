//
//  RecordingFile.swift
//  AppLocalizer
//

import Foundation

/// A Simulator recording kept with the app's recordings for its App
/// Preview: its checksum (the file's name), where it is, its size the way
/// it plays, and how long it lasts.
struct RecordingFile: Hashable, Sendable {
    var id: String
    var url: URL
    var pixelSize: PixelSize
    var seconds: Double
}
