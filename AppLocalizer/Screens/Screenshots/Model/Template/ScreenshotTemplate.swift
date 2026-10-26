//
//  ScreenshotTemplate.swift
//  AppLocalizer
//

import Foundation

/// One app's screenshot template: the layout every locale is rendered with,
/// so per locale only the caption and the capture change. This is the
/// contract the renderer and the assistant tools share (design README §3,
/// schema `applocalizer.screenshot-template/1`): it encodes to exactly that
/// JSON, keys included.
///
/// Lengths are fractions of the canvas (0–1) or `u`, where 1 u is the
/// canvas's short side ÷ 1320, so one template holds for iPhone and iPad,
/// portrait and landscape. Any field can be overridden for one slot
/// (`Slot.over`, on dotted paths); `value(at:slot:)` and
/// `resolved(forSlot:)` apply the order slot override → template.
///
/// `version` is set by AppLocalizer: each save, accepted proposal or
/// restore makes a new one (`TemplateHistory`).
struct ScreenshotTemplate: Codable, Hashable, Sendable {
    static let schemaIdentifier = "applocalizer.screenshot-template/1"

    var schema = Self.schemaIdentifier
    var id: String
    var name: String
    var version: Int
    /// The starter the template began from, if any.
    var starter: TemplateStarter?
    var canvas: TemplateCanvas
    var background: TemplateBackground
    var device: TemplateDevice
    var caption: TemplateCaption
    var fit: TemplateFit
    var rightToLeft: TemplateRightToLeft
    var safeArea: TemplateSafeArea
    var fonts: TemplateFonts
    var slots: [TemplateSlot]

    enum CodingKeys: String, CodingKey {
        case schema, id, name, version, starter, canvas
        case background = "bg"
        case device, caption, fit
        case rightToLeft = "rtl"
        case safeArea = "safe"
        case fonts, slots
    }

    /// The most slots a set can have on the App Store.
    static let maximumSlots = 10

    /// Whether slot `index` uses the hero layout: headline ×1.06, room for
    /// a subhead, device ×0.96.
    func isHero(slot index: Int) -> Bool {
        slots.indices.contains(index) && slots[index].layout == .hero
    }
}
