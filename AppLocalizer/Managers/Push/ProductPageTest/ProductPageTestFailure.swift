//
//  ProductPageTestFailure.swift
//  AppLocalizer
//

import Foundation

/// Why a step of a test didn't go, worded for its row.
enum ProductPageTestFailure: Error, Hashable, Sendable {
    /// App Store Connect refused the artwork on the treatment's page: its
    /// placement type isn't one a treatment takes, maybe.
    case placementRefused(placementType: String, detail: String)
    /// No placement group takes the variant's size.
    case noMatchingGroup(placementType: String, pixelSize: PixelSize, accepted: [PixelSize])
    case file(detail: String)
    case processing(state: String, details: String?)
    case processingTimedOut
    case upload(detail: String)

    var text: String {
        switch self {
        case let .placementRefused(placementType, detail):
            String(localized: "App Store Connect didn’t take \(ExtrasPushKind.name(ofPlacementType: placementType)) on the test’s treatment (\(detail)).")
        case let .noMatchingGroup(placementType, pixelSize, accepted):
            ExtrasPushFailure.noMatchingGroup(placementType: placementType, pixelSize: pixelSize, isVideo: false, accepted: accepted).text
        case let .file(detail):
            String(localized: "The variant couldn’t be read (\(detail)).")
        case let .processing(state, details):
            String(localized: "Apple couldn’t process the variant (\(details ?? state)).")
        case .processingTimedOut:
            String(localized: "Apple was still processing the variant when AppLocalizer stopped waiting.")
        case let .upload(detail):
            String(localized: "The variant didn’t upload (\(detail)).")
        }
    }
}
