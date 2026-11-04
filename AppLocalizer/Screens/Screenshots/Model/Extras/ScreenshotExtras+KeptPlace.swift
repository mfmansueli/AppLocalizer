//
//  ScreenshotExtras+KeptPlace.swift
//  AppLocalizer
//

import Foundation

/// A run that makes only the header or only search results leaves the
/// other place as it is: the set keeps that place's artwork from before,
/// drawn as it was made, so the preview, Captions and Review & Push still
/// have both.
extension ScreenshotExtras {
    /// How the artwork of `kind` is drawn: the kept place's own, else the
    /// set's.
    func place(_ kind: AutopilotArtworkKind) -> ExtrasArtworkPlace {
        if let keptPlace, keptPlace.kind == kind { return keptPlace }
        return ExtrasArtworkPlace(
            kind: kind, directionName: directionName, template: artworkTemplate, page: artworkDesign?.page(for: kind),
            shows: artworkShows, searchSlot: searchSlot, motion: artworkMotion
        )
    }

    /// Keeps the place `size` doesn't make from `before`, when it has that
    /// place's own artwork. One 16:9 image from before is both places, so
    /// it goes.
    mutating func keepOtherPlace(from before: ScreenshotExtras?, making size: AutopilotArtworkSize) {
        guard let kind = size.keptKind, let before, before.artworkSize != nil else { return }
        let files = before.artwork.filter { $0.kind == kind }
        guard !files.isEmpty else { return }
        artwork.removeAll { $0.kind == kind }
        artwork += files
        keptPlace = before.place(kind)
        artworkSize = .headerAndSearch
    }
}
