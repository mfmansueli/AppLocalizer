//
//  ArtworkSafeArea.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// What of each artwork every device shows: the phones and the text go
/// inside it, the background runs to the edges. From the design canvas
/// (board 32), which replaced the ART SAFE AREA rectangles measured from
/// Apple's creative-asset template (Blake Crosley, "The 2026 App Store
/// Product Page: Every Surface, Measured") on 2026-11-03:
///
/// - The header: on iPhone only the middle shows, 17% goes on each side,
///   and the status bar, Back and Share sit over the top 22%.
/// - Search results: the whole image shows, small, next to the app's name
///   and Get.
/// - The 16:9 image: the header's sides, and below the 12% the header's
///   crop leaves out at the top.
///
/// These are assumptions; check them against Apple's template files when
/// they come out.
enum ArtworkSafeArea {
    /// In the kind's own pixels.
    static func rect(for kind: AutopilotArtworkKind) -> CGRect {
        switch kind {
        // 3840 × 1646: 17% off each side, 22% off the top.
        case .header: CGRect(x: 653, y: 362, width: 2534, height: 1284)
        // 3840 × 2560: all of it.
        case .search: CGRect(x: 0, y: 0, width: 3840, height: 2560)
        // 5244 × 2950: 17% off each side, 12% off the top.
        case .wide: CGRect(x: 891, y: 354, width: 3462, height: 2596)
        }
    }

    /// The part of the header iPhone shows, as fractions: what Show iPhone
    /// Area marks in the viewer.
    static let iPhoneHeaderTop = 0.22
    static let iPhoneHeaderSide = 0.17

    /// The same rectangle as fractions of the artwork, 0–1.
    static func fraction(for kind: AutopilotArtworkKind) -> CGRect {
        let rect = rect(for: kind)
        let size = kind.pixelSize.cgSize
        return CGRect(x: rect.minX / size.width, y: rect.minY / size.height, width: rect.width / size.width, height: rect.height / size.height)
    }

    /// How much of the top and of each side lies outside the safe area, in
    /// whole percents of the artwork: 22 and 17 for the header.
    static func percentInsets(for kind: AutopilotArtworkKind) -> (top: Int, side: Int) {
        let fraction = fraction(for: kind)
        return (Int((fraction.minY * 100).rounded()), Int((fraction.minX * 100).rounded()))
    }

    /// Whether `frame` lies inside the kind's safe area, give or take
    /// `tolerance` pixels.
    static func contains(_ frame: CGRect, in kind: AutopilotArtworkKind, tolerance: CGFloat = 2) -> Bool {
        rect(for: kind).insetBy(dx: -tolerance, dy: -tolerance).contains(frame)
    }
}
