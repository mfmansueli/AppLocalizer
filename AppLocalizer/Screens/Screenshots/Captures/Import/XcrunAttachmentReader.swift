//
//  XcrunAttachmentReader.swift
//  AppLocalizer
//

import Foundation

/// Runs `xcrun xcresulttool export attachments --path <bundle>
/// --output-path <folder>` (Xcode 16 and later). When it can't run, the
/// error says how to export the attachments by hand and drop that folder.
struct XcrunAttachmentReader: XcresultAttachmentReader {
    func exportAttachments(of bundle: URL, to directory: URL) async throws {
        try await Task.detached {
            let process = Process()
            process.executableURL = URL(filePath: "/usr/bin/xcrun")
            process.arguments = ["xcresulttool", "export", "attachments", "--path", bundle.path, "--output-path", directory.path]
            let errors = Pipe()
            process.standardError = errors
            process.standardOutput = Pipe()
            do {
                try process.run()
            } catch {
                throw CaptureImportError.xcresultUnreadable(bundle.lastPathComponent)
            }
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw CaptureImportError.xcresultUnreadable(bundle.lastPathComponent)
            }
        }.value
    }
}
