//
//  ScreenshotsServices+Extras.swift
//  AppLocalizer
//

import Foundation

/// Where the App Preview's recordings, the App Previews and the header and
/// search artwork are kept by default: a temporary folder per app.
extension ScreenshotsServices {
    func storeRecording(_ data: Data, for app: StoreApp) async throws -> RecordingFile {
        try await RecordingFileReader.store(data, in: Self.temporaryFolder(for: app, named: "Recordings"))
    }

    func recordingURL(_ fileID: String, for app: StoreApp) -> URL {
        Self.temporaryFolder(for: app, named: "Recordings").appending(path: "\(fileID).mov")
    }

    func extrasFolder(for app: StoreApp) -> URL {
        Self.temporaryFolder(for: app, named: "Extras")
    }

    /// Where one of the extras' files is: `<checksum>.png` or `.mp4`.
    func extrasFileURL(_ fileID: String, pathExtension: String, for app: StoreApp) -> URL {
        extrasFolder(for: app).appending(path: "\(fileID).\(pathExtension)")
    }

    /// Where an image or video the person attached for the artwork is.
    func referenceURL(_ reference: AutopilotArtworkReference, for app: StoreApp) -> URL {
        extrasFolder(for: app).appending(path: "References/\(reference.fileID)")
    }

    static func temporaryFolder(for app: StoreApp, named name: String) -> URL {
        FileManager.default.temporaryDirectory.appending(path: "AppLocalizerAutopilot/\(app.id)/\(name)", directoryHint: .isDirectory)
    }
}
