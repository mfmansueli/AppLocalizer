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
/// (`Slot.over`, on dotted paths), and for landscape canvases (`lan`,
/// the same paths: iPad lying down and Mac); `value(at:slot:)` and
/// `resolved(forSlot:)` apply the order landscape override → slot override
/// → template.
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
    /// Shapes, laurels, badges and props; usually set per slot instead.
    var decorations: [TemplateDecoration]?
    var slots: [TemplateSlot]
    /// Overrides for landscape canvases (iPad lying down, Mac), on dotted
    /// paths like a slot's; they win over the slot's own. Arcade's smaller
    /// caps and unpinned device, for one. Saved as `lan`; templates saved
    /// before still read `landscape`.
    var landscape: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case schema, id, name, version, starter, canvas
        case background = "bg"
        case device, caption, fit
        case rightToLeft = "rtl"
        case safeArea = "safe"
        case fonts
        case decorations = "deco"
        case slots
        case landscape = "lan"
    }

    /// The key landscape overrides were saved under before `lan`.
    private enum LegacyKeys: String, CodingKey {
        case landscape
    }

    /// The most slots a set can have on the App Store.
    static let maximumSlots = 10

    /// Whether slot `index` uses the hero layout: headline ×1.06, room for
    /// a subhead, device ×0.96.
    func isHero(slot index: Int) -> Bool {
        slots.indices.contains(index) && slots[index].layout == .hero
    }

    /// Whether slot `index` uses Two phones: its capture in front, the slot
    /// before it's behind.
    func isPair(slot index: Int) -> Bool {
        slots.indices.contains(index) && slots[index].layout == .pair
    }

    /// Whether slot `index` is a Reviews slot: no device, real App Store
    /// reviews under the headline.
    func isQuotes(slot index: Int) -> Bool {
        slots.indices.contains(index) && slots[index].layout == .quotes
    }

    /// Whether any slot shows App Store reviews.
    var showsReviews: Bool {
        slots.contains { $0.layout == .quotes }
    }

    /// The display slot whose capture stands behind on display slot `slot`
    /// of `count`: the one before it (the last one, for the first), when
    /// `templateSlot` uses Two phones.
    func behindSlot(_ slot: Int, templateSlot: Int, count: Int) -> Int? {
        guard isPair(slot: templateSlot), count > 1 else { return nil }
        return (slot - 1 + count) % count
    }
}

extension ScreenshotTemplate {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schema = try container.decode(String.self, forKey: .schema)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        version = try container.decode(Int.self, forKey: .version)
        starter = try container.decodeIfPresent(TemplateStarter.self, forKey: .starter)
        canvas = try container.decode(TemplateCanvas.self, forKey: .canvas)
        background = try container.decode(TemplateBackground.self, forKey: .background)
        device = try container.decode(TemplateDevice.self, forKey: .device)
        caption = try container.decode(TemplateCaption.self, forKey: .caption)
        fit = try container.decode(TemplateFit.self, forKey: .fit)
        rightToLeft = try container.decode(TemplateRightToLeft.self, forKey: .rightToLeft)
        safeArea = try container.decode(TemplateSafeArea.self, forKey: .safeArea)
        fonts = try container.decode(TemplateFonts.self, forKey: .fonts)
        decorations = try container.decodeIfPresent([TemplateDecoration].self, forKey: .decorations)
        slots = try container.decode([TemplateSlot].self, forKey: .slots)
        landscape = try container.decodeIfPresent([String: JSONValue].self, forKey: .landscape)
            ?? decoder.container(keyedBy: LegacyKeys.self).decodeIfPresent([String: JSONValue].self, forKey: .landscape)
    }
}
