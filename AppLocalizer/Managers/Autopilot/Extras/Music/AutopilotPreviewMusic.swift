//
//  AutopilotPreviewMusic.swift
//  AppLocalizer
//

import Foundation

/// The plan's App Preview music: a library track (Warm acoustic by
/// default), or the person's own file, copied into the app's Extras folder
/// once they confirmed they hold the rights.
struct AutopilotPreviewMusic: Codable, Hashable, Sendable {
    var track: AppPreviewTrack = .warmAcoustic
    /// The own file's ID in the Extras folder (its checksum).
    var fileID: String?
    /// The own file's extension, e.g. "m4a".
    var fileExtension: String?
    /// "lumen-theme.m4a".
    var fileName: String?

    static let standard = AutopilotPreviewMusic()

    /// The library track.
    init(track: AppPreviewTrack = .warmAcoustic) {
        self.track = track
    }

    /// The person's own file.
    init(fileID: String, fileExtension: String, fileName: String) {
        track = .ownFile
        self.fileID = fileID
        self.fileExtension = fileExtension
        self.fileName = fileName
    }

    /// The own file, when there is one.
    var hasFile: Bool { fileID != nil && fileExtension != nil }

    /// "Warm acoustic", "Your file: lumen-theme.m4a".
    var title: String {
        guard track == .ownFile, let fileName else { return track.title }
        return String(localized: "Your file: \(fileName)")
    }
}
