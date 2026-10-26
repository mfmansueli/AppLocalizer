//
//  LayoutBackground.swift
//  AppLocalizer
//

import Foundation

/// The canvas background, resolved from `bg`.
enum LayoutBackground: Hashable, Sendable {
    case solid(TemplateColor)
    /// CSS-style angle in degrees: 0 points up, 90 right.
    case linear(angle: Double, stops: [TemplateColor])
    case panorama(LayoutPanorama)

    init(_ background: TemplateBackground, slot: Int, slotCount: Int, isMirrored: Bool) {
        let stops = background.stops.compactMap(TemplateColor.init)
        let first = stops.first ?? TemplateColor(red: 0.2, green: 0.2, blue: 0.2)
        switch background.kind {
        case .solid, .image:
            // Image backgrounds draw their first stop until assets exist.
            self = .solid(first)
        case .linear:
            self = stops.count > 1 ? .linear(angle: background.angle ?? 180, stops: stops) : .solid(first)
        case .panorama:
            self = .panorama(LayoutPanorama(stops: stops.isEmpty ? [first] : stops, slotCount: slotCount, slot: slot, isMirrored: isMirrored))
        }
    }
}
