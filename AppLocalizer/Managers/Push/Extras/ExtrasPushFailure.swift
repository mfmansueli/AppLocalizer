//
//  ExtrasPushFailure.swift
//  AppLocalizer
//

import Foundation

/// Why one extra didn't go, worded for its progress row: what failed and
/// what that means for the App Store page.
enum ExtrasPushFailure: Error, Hashable, Sendable {
    /// The made file couldn't be read from this Mac.
    case file(detail: String)
    /// App Store Connect has no asset library for the app.
    case noLibrary(detail: String)
    /// No placement group of this type takes a file of this size.
    case noMatchingGroup(placementType: String, pixelSize: PixelSize, isVideo: Bool, accepted: [PixelSize])
    /// A part of the file didn't upload.
    case part(Int, count: Int, timedOut: Bool, detail: String)
    /// Apple couldn't process the file, with its reasons if it gave any.
    case processing(state: String, details: String?)
    /// Apple was still processing the file when the push stopped waiting.
    case processingTimedOut
    /// The device's App Preview group is full and this one replaces none
    /// of them.
    case previewsFull(group: String, limit: Int)
    /// The placement was refused after what was in its slot was taken off:
    /// `restored` says whether that came back.
    case placing(detail: String, restored: Bool)

    /// The row's red line.
    var text: String {
        switch self {
        case let .file(detail):
            return String(localized: "The file couldn’t be read (\(detail)). Nothing was uploaded.")
        case let .noLibrary(detail):
            return String(localized: "App Store Connect has no asset library for this app (\(detail)). Nothing was uploaded.")
        case let .noMatchingGroup(placementType, pixelSize, isVideo, accepted):
            let place = ExtrasPushKind.name(ofPlacementType: placementType)
            let file = isVideo ? String(localized: "a \(pixelSize.title) video") : String(localized: "a \(pixelSize.title) image")
            guard !accepted.isEmpty else { return String(localized: "App Store Connect doesn’t take \(file) for \(place). Nothing was uploaded.") }
            let sizes = accepted.map(\.title).formatted(.list(type: .or))
            return String(localized: "App Store Connect doesn’t take \(file) for \(place); it takes \(sizes). Nothing was uploaded.")
        case let .part(part, count, timedOut, detail):
            if timedOut { return String(localized: "Upload timed out on part \(part) of \(count). Nothing was placed.") }
            return String(localized: "Upload failed on part \(part) of \(count) (\(detail)). Nothing was placed.")
        case let .processing(state, details):
            let reason = details ?? state
            return String(localized: "Apple couldn’t process the file (\(reason)). Nothing was placed.")
        case .processingTimedOut:
            return String(localized: "Apple was still processing the file. It’s uploaded; Retry Failed places it once it’s ready.")
        case let .previewsFull(group, limit):
            return String(
                localized: "\(group) already has \(limit) App Previews, the most it holds, and this one replaces none of them. Nothing was uploaded."
            )
        case let .placing(detail, restored):
            if restored { return String(localized: "Couldn’t place it (\(detail)). What was there before was put back.") }
            return String(localized: "Couldn’t place it (\(detail)). What was there before was taken off and couldn’t be put back.")
        }
    }
}
