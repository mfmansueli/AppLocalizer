//
//  TemplateTilt.swift
//  AppLocalizer
//

import Foundation

/// `device.tilt`: the device rotated, turned and leaned back, in degrees
/// (`rz`, `ry`, `rx` in JSON). Drawn as a 2D transform (rotate, skew,
/// scale), not real perspective, so dozens of thumbnails stay cheap to
/// draw. Rotate and turn are mirrored in right-to-left locales. Usually set
/// per slot.
struct TemplateTilt: Codable, Hashable, Sendable {
    /// Around the device's center; positive turns clockwise.
    var rotate: Double
    /// Around the vertical axis.
    var turn: Double
    /// Around the horizontal axis.
    var lean: Double

    static let flat = TemplateTilt(rotate: 0, turn: 0, lean: 0)

    /// The ranges the template editor's sliders offer.
    static let rotateRange: ClosedRange<Double> = -30...30
    static let turnRange: ClosedRange<Double> = -30...30
    static let leanRange: ClosedRange<Double> = 0...40

    /// What a template may hold: a little more than the sliders.
    static let schemaRotateRange: ClosedRange<Double> = -45...45
    static let schemaTurnRange: ClosedRange<Double> = -45...45
    static let schemaLeanRange: ClosedRange<Double> = 0...60

    enum CodingKeys: String, CodingKey {
        case rotate = "rz"
        case turn = "ry"
        case lean = "rx"
    }

    init(rotate: Double, turn: Double, lean: Double) {
        self.rotate = rotate
        self.turn = turn
        self.lean = lean
    }

    /// An angle left out is 0, so `{ "rz": 6 }` is a plain rotation.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rotate = try container.decodeIfPresent(Double.self, forKey: .rotate) ?? 0
        turn = try container.decodeIfPresent(Double.self, forKey: .turn) ?? 0
        lean = try container.decodeIfPresent(Double.self, forKey: .lean) ?? 0
    }

    var isFlat: Bool { rotate == 0 && turn == 0 && lean == 0 }

    /// "rotate 5°, turn −16°, lean back 6°", leaving out angles at 0.
    var summary: String {
        var parts: [String] = []
        if rotate != 0 { parts.append(String(localized: "rotate \(rotate.formatted())°")) }
        if turn != 0 { parts.append(String(localized: "turn \(turn.formatted())°")) }
        if lean != 0 { parts.append(String(localized: "lean back \(lean.formatted())°")) }
        return parts.isEmpty ? String(localized: "flat") : parts.joined(separator: ", ")
    }
}
