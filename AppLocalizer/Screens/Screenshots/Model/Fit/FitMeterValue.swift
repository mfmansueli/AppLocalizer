//
//  FitMeterValue.swift
//  AppLocalizer
//

import Foundation

/// The fit meter's geometry: how full the bar is and where its two ticks
/// sit. The first tick is what fits at full size (fill 1.0); the second,
/// size ÷ min, is the most that fits at the smallest size. Past it the
/// caption overflows. All values are fractions of the bar's width.
struct FitMeterValue: Hashable, Sendable {
    var filled: Double
    var fullSizeTick: Double
    var smallestSizeTick: Double
    var tone: FitTone

    init(fit: CaptionFit) {
        let limit = fit.minimumSize > 0 ? fit.fullSize / fit.minimumSize : 1
        let scale = max(limit * 1.3, 1.4)
        let shown = fit.fits ? fit.fill : max(fit.fill, limit * 1.08)
        filled = fit.isEmpty ? 0 : min(1, shown / scale)
        fullSizeTick = 1 / scale
        smallestSizeTick = limit / scale
        tone = fit.tone
    }
}
