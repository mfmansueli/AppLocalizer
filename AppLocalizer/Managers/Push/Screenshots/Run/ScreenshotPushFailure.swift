//
//  ScreenshotPushFailure.swift
//  AppLocalizer
//

import Foundation

/// Why one image didn't go, worded for the progress row: what failed and
/// what that means for the live screenshot.
enum ScreenshotPushFailure: Error, Hashable, Sendable {
    /// A part of the file didn't upload.
    case part(Int, count: Int, timedOut: Bool, detail: String)
    /// Apple accepted the file but couldn't process it.
    case processing(code: String)
    /// The live screenshot couldn't be downloaded to keep, so it wasn't
    /// replaced.
    case keepingCopy(detail: String)
    /// The live screenshot is still being processed in App Store Connect,
    /// so there's no image to keep yet and it wasn't replaced.
    case liveStillProcessing
    /// The PNG couldn't be made.
    case image
    /// The set already holds ten screenshots and none of them is this
    /// image's to replace.
    case setFull
    /// App Store Connect refused a request.
    case request(detail: String)

    /// The row's red line. `replaces` says whether a live screenshot was
    /// there, which is what "stays" refers to.
    func text(replaces: Bool) -> String {
        let stays = replaces
            ? String(localized: "Nothing was replaced; the live screenshot stays.")
            : String(localized: "Nothing was added to the set.")
        switch self {
        case let .part(part, count, timedOut, detail):
            if timedOut { return String(localized: "Upload timed out on part \(part) of \(count). \(stays)") }
            return String(localized: "Upload failed on part \(part) of \(count) (\(detail)). \(stays)")
        case let .processing(code):
            let outcome = replaces ? String(localized: "The live screenshot stays.") : String(localized: "Nothing was added to the set.")
            return String(localized: "Apple couldn’t process the image (\(code)). \(outcome)")
        case let .keepingCopy(detail):
            return String(localized: "Couldn’t keep a copy of the live screenshot (\(detail)), so it wasn’t replaced.")
        case .liveStillProcessing:
            return String(localized: "The live screenshot is still processing in App Store Connect, so it wasn’t replaced. Try again in a few minutes.")
        case .image:
            return String(localized: "The image couldn’t be made. \(stays)")
        case .setFull:
            return String(localized: "The set already has 10 screenshots. \(stays)")
        case let .request(detail):
            return "\(detail) \(stays)"
        }
    }
}
