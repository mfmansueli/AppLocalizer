//
//  ArtworkWebMeasure+CaptionFit.swift
//  AppLocalizer
//

import Foundation

extension ArtworkWebMeasure.Element {
    /// The text's fit as Captions' meter shows it, in canvas pixels: the
    /// size it's set at, its full size before `data-al-fit` shrank it,
    /// and whether it stays in its box.
    var captionFit: CaptionFit {
        let size = fontSize ?? 0
        let scale = min(max(fitScale ?? 1, 0.01), 1)
        let full = size / scale
        let words = text ?? ""
        return CaptionFit(
            text: words, lines: [words], size: size, fullSize: full, minimumSize: full * ArtworkLayoutEngine.smallestScale,
            maxLines: 1, fits: fits, hasWideWord: false, fill: 0
        )
    }
}
