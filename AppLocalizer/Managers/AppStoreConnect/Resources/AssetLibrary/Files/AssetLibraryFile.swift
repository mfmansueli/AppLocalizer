//
//  AssetLibraryFile.swift
//  AppLocalizer
//

import Foundation

/// One image or video in an app's App Asset Library, as the library sheet
/// lists it: its names, size, state, when it was uploaded and a thumbnail.
struct AssetLibraryFile: Hashable, Sendable, Identifiable {
    var id: String
    var media: AssetLibraryMedia
    /// "Autopilot · en-US · Header 21:9 · motion · 3F2A9C".
    var referenceName: String?
    var fileName: String?
    var fileSize: Int?
    /// Apple's state, e.g. `PREPARE_FOR_SUBMISSION`, `APPROVED`, `FAILED`.
    var state: String?
    var createdDate: Date?
    /// Apple's image URL with `{w}`, `{h}` and `{f}` to fill in: the image,
    /// or a video's poster frame.
    var thumbnailTemplate: String?
    var pixelSize: PixelSize?

    var asset: AssetLibraryAsset { AssetLibraryAsset(id: id, media: media) }

    /// The name to show: the reference name, else the file's.
    var title: String {
        if let referenceName, !referenceName.isEmpty { return referenceName }
        return fileName ?? id
    }

    /// Uploaded by an Autopilot push.
    var isFromAutopilot: Bool { referenceName?.hasPrefix("Autopilot · ") == true }

    /// The thumbnail at `width` points wide (doubled for Retina), keeping
    /// the file's shape.
    func thumbnailURL(width: CGFloat) -> URL? {
        guard let thumbnailTemplate else { return nil }
        let pixels = Int(width * 2)
        let height = pixelSize.map { size in Int((Double(pixels) * Double(size.height) / Double(max(1, size.width))).rounded()) } ?? pixels
        let filled = thumbnailTemplate
            .replacingOccurrences(of: "{w}", with: "\(pixels)")
            .replacingOccurrences(of: "{h}", with: "\(height)")
            .replacingOccurrences(of: "{f}", with: "png")
        return URL(string: filled)
    }

    /// "Ready", "Processing", "Approved", "Failed"… from Apple's state.
    var stateTitle: String {
        switch state {
        case "AWAITING_UPLOAD": String(localized: "Upload not finished")
        case "UPLOAD_COMPLETE": String(localized: "Processing")
        case "PREPARE_FOR_SUBMISSION": String(localized: "Ready")
        case "READY_FOR_REVIEW", "WAITING_FOR_REVIEW": String(localized: "Waiting for review")
        case "IN_REVIEW": String(localized: "In review")
        case "ACCEPTED", "APPROVED": String(localized: "Approved")
        case "REJECTED": String(localized: "Rejected")
        case "FAILED": String(localized: "Failed")
        case "ARCHIVED": String(localized: "Archived")
        default: state ?? String(localized: "Unknown")
        }
    }
}
