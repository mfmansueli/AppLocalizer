//
//  LayoutDevice+Paths.swift
//  AppLocalizer
//

import SwiftUI

extension LayoutDevice {
    /// The body's outline: square on the hinge side of a folded iPhone Duo.
    func bodyPath(_ rect: CGRect, cornerRadius radius: CGFloat) -> Path {
        Self.path(rect, cornerRadius: radius, hingeRadius: spine.map { min(radius, $0.bodyCornerRadius) })
    }

    /// The screen's outline: square on the hinge side of a folded iPhone
    /// Duo, as its cover display is.
    func screenPath(_ rect: CGRect, cornerRadius radius: CGFloat) -> Path {
        Self.path(rect, cornerRadius: radius, hingeRadius: spine.map { min(radius, $0.screenCornerRadius) })
    }

    /// Left corners `hingeRadius` (when there's a hinge), right ones
    /// `radius`. The hinge stays on the left: the capture is never
    /// mirrored.
    private static func path(_ rect: CGRect, cornerRadius radius: CGFloat, hingeRadius: CGFloat?) -> Path {
        guard let hingeRadius else { return Path(roundedRect: rect, cornerRadius: radius, style: .continuous) }
        return UnevenRoundedRectangle(
            topLeadingRadius: hingeRadius, bottomLeadingRadius: hingeRadius, bottomTrailingRadius: radius, topTrailingRadius: radius,
            style: .continuous
        ).path(in: rect)
    }
}
