//
//  ArtworkWebError.swift
//  AppLocalizer
//

import Foundation

/// Why a Claude Design page couldn't be rendered.
enum ArtworkWebError: LocalizedError, Equatable {
    case setupFailed
    case loadFailed(String)
    case scriptFailed(String)
    case snapshotFailed
    case tooLarge(Int)
    case timedOut

    var errorDescription: String? {
        switch self {
        case .setupFailed:
            String(localized: "The page renderer couldn’t be set up.")
        case let .loadFailed(reason):
            String(localized: "The page didn’t load: \(reason)")
        case let .scriptFailed(reason):
            String(localized: "AppLocalizer couldn’t fill in the page: \(reason)")
        case .snapshotFailed:
            String(localized: "The page couldn’t be drawn.")
        case let .tooLarge(bytes):
            String(localized: "The page is \(bytes.formatted(.byteCount(style: .file))); keep it under \(AutopilotArtworkDesign.maximumBytes.formatted(.byteCount(style: .file))).")
        case .timedOut:
            String(localized: "The page took too long to load.")
        }
    }
}
