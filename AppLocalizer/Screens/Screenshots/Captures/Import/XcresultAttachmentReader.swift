//
//  XcresultAttachmentReader.swift
//  AppLocalizer
//

import Foundation

/// Exports the attachments of an Xcode result bundle into a folder, with
/// the `manifest.json` that says which test, device and configuration
/// each came from. `XcrunAttachmentReader` runs `xcresulttool`; tests
/// write the folder themselves.
protocol XcresultAttachmentReader: Sendable {
    func exportAttachments(of bundle: URL, to directory: URL) async throws
}
