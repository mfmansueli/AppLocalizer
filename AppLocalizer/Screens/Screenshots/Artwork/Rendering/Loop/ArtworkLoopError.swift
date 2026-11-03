//
//  ArtworkLoopError.swift
//  AppLocalizer
//

import Foundation

/// Why a header or search motion loop couldn't be made.
enum ArtworkLoopError: LocalizedError, Equatable {
    case writerFailed(String)
    case drawingFailed
    case layersFailed

    var errorDescription: String? {
        switch self {
        case let .writerFailed(reason) where reason.isEmpty: String(localized: "The loop couldn’t be written.")
        case let .writerFailed(reason): String(localized: "The loop couldn’t be written: \(reason)")
        case .drawingFailed: String(localized: "A frame of the loop couldn’t be drawn.")
        case .layersFailed: String(localized: "The artwork couldn’t be drawn for the loop.")
        }
    }
}
