//
//  CaptureFile.swift
//  AppLocalizer
//

import Foundation

/// A capture image kept with the app's captures: its checksum (the file's
/// name) and size.
struct CaptureFile: Hashable, Sendable {
    var id: String
    var pixelSize: PixelSize
}
