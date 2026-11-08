//
//  TemplateDevicePair.swift
//  AppLocalizer
//

import Foundation

/// `device.pair`: where the phone behind sits on a Two phones slot. It's
/// the front phone's size and shape, flat, showing the capture of the slot
/// before; mirrored in right-to-left locales.
struct TemplateDevicePair: Codable, Hashable, Sendable {
    /// Shift right from the centered position (`dx`), as a fraction of the
    /// canvas width; negative moves it left.
    var shiftRight: Double
    /// Its top edge as a fraction of the canvas height, never over the
    /// caption; 0.12 above where the caption leaves room when left out.
    var top: Double?

    enum CodingKeys: String, CodingKey {
        case shiftRight = "dx"
        case top
    }

    /// Behind and to the left, higher up: what a slot gets without its
    /// own `device.pair`.
    static let standard = TemplateDevicePair(shiftRight: -0.22, top: 0.25)

    init(shiftRight: Double, top: Double? = nil) {
        self.shiftRight = shiftRight
        self.top = top
    }

    /// A shift left out is 0.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        shiftRight = try container.decodeIfPresent(Double.self, forKey: .shiftRight) ?? 0
        top = try container.decodeIfPresent(Double.self, forKey: .top)
    }

    /// "22% left, top at 25%".
    var summary: String {
        let shift = (abs(shiftRight) * 100).formatted(.number.precision(.fractionLength(0...1)))
        let side = shiftRight < 0 ? String(localized: "\(shift)% left") : String(localized: "\(shift)% right")
        guard let top else { return side }
        let topText = (top * 100).formatted(.number.precision(.fractionLength(0...1)))
        return String(localized: "\(side), top at \(topText)%")
    }
}
