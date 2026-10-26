//
//  PixelSize.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// An image's size in whole pixels, e.g. 1320 × 2868.
struct PixelSize: Codable, Hashable, Sendable {
    var width: Int
    var height: Int

    var cgSize: CGSize { CGSize(width: width, height: height) }

    var isLandscape: Bool { width > height }

    /// The same size turned 90°.
    var rotated: PixelSize { PixelSize(width: height, height: width) }

    /// Long side ÷ short side: about 2.17 for iPhones, 1.33 for iPads.
    var aspectRatio: Double {
        let short = Double(min(width, height))
        return short > 0 ? Double(max(width, height)) / short : 0
    }

    /// "1320 × 2868".
    var title: String { "\(width) × \(height)" }
}
