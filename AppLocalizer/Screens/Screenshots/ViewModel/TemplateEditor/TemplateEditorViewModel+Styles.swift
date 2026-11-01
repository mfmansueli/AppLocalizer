//
//  TemplateEditorViewModel+Styles.swift
//  AppLocalizer
//

import Foundation

// The gallery templates' looks in the inspector: the device's angle and a
// slot's own background (both per slot), the headline's uppercase,
// emphasized line and highlight bars, and the caption color, which edits
// the slot's override when the slot has one.
extension TemplateEditorViewModel {
    /// How the emphasized line differs.
    enum EmphasisStyle: Hashable, CaseIterable {
        case light
        case heavy
        case italic

        var title: String {
            switch self {
            case .light: String(localized: "Light")
            case .heavy: String(localized: "Heavy")
            case .italic: String(localized: "Italic")
            }
        }
    }

    /// The highlight a new one starts from: lavender bars, tilted 2°.
    static let defaultHighlight = TemplateHighlight(color: "#CFAEFF", padding: 0.2, rotation: -2, radius: 0.05)

    /// The template as this slot sees it.
    var slotTemplate: ScreenshotTemplate? {
        template?.resolved(forSlot: slot)
    }

    /// Sets this slot's override of `path`; nil clears it.
    func setSlotOverride(_ path: String, to value: JSONValue?) {
        set("slots.\(slot).over.\(path)", to: value ?? .null)
    }

    private func slotHasOverride(_ path: String) -> Bool {
        guard let template, template.slots.indices.contains(slot) else { return false }
        return template.slots[slot].over[path] != nil
    }

    // MARK: - Angle

    /// The angle this slot's device is drawn at.
    var slotTilt: TemplateTilt {
        slotTemplate?.device.tilt ?? .flat
    }

    /// Rotate, Turn and Lean back write the slot's angle; the template's
    /// own angle clears the override.
    func setSlotTilt(_ tilt: TemplateTilt) {
        let own = template?.device.tilt ?? .flat
        setSlotOverride("device.tilt", to: tilt == own ? nil : ScreenshotTemplate.encoded(tilt))
    }

    // MARK: - Background

    /// What the Background section edits: the slot's own background when
    /// it has one, else the template's.
    var effectiveBackground: TemplateBackground? {
        slotTemplate?.background
    }

    var hasOwnBackground: Bool { slotHasOverride("bg") }

    /// A slot can't have its own panorama: a panorama spans every slot.
    var canGiveOwnBackground: Bool {
        !hasOwnBackground && template?.background.kind != .panorama
    }

    func giveSlotOwnBackground() {
        guard let background = template?.background else { return }
        setSlotOverride("bg", to: ScreenshotTemplate.encoded(background))
    }

    func useTemplateBackground() {
        setSlotOverride("bg", to: nil)
    }

    /// Edits the slot's own background in place.
    func editOwnBackground(_ change: (inout TemplateBackground) -> Void) {
        guard var background = effectiveBackground else { return }
        change(&background)
        setSlotOverride("bg", to: ScreenshotTemplate.encoded(background))
    }

    // MARK: - Caption

    /// The color this slot's caption is drawn in.
    var slotInk: String {
        slotTemplate?.caption.ink ?? "#FFFFFF"
    }

    /// The Color well: the slot's override when it has one, else the
    /// template's ink.
    func setInk(_ color: String) {
        if slotHasOverride("caption.ink") {
            setSlotOverride("caption.ink", to: .string(color))
        } else {
            set("caption.ink", to: .string(color))
        }
    }

    var isUppercase: Bool { template?.caption.headline.isUppercase ?? false }

    func setUppercase(_ isOn: Bool) {
        set("caption.headline.upper", to: isOn ? .bool(true) : .null)
    }

    var emphasisLine: TemplateEmphasis.Line? { template?.caption.headline.emphasis?.line }

    /// None, First line or Last line: a new emphasis is light under a bold
    /// headline and heavy under a light one.
    func setEmphasisLine(_ line: TemplateEmphasis.Line?) {
        guard let headline = template?.caption.headline else { return }
        guard let line else {
            set("caption.headline.emph", to: .null)
            return
        }
        var emphasis = headline.emphasis ?? TemplateEmphasis(line: line, weight: headline.weight >= 700 ? 400 : 800)
        emphasis.line = line
        set("caption.headline.emph", to: ScreenshotTemplate.encoded(emphasis))
    }

    var emphasisStyle: EmphasisStyle? {
        guard let emphasis = template?.caption.headline.emphasis else { return nil }
        if emphasis.italic == true { return .italic }
        return (emphasis.weight ?? 400) >= 700 ? .heavy : .light
    }

    /// Light pairs Archivo Black with Archivo, the lighter cut of the same
    /// family; Heavy uses the headline's font.
    func setEmphasisStyle(_ style: EmphasisStyle) {
        guard let template, var emphasis = template.caption.headline.emphasis else { return }
        switch style {
        case .italic:
            emphasis.italic = true
        case .light:
            emphasis.italic = nil
            emphasis.weight = 400
            if template.fonts.display == "Archivo Black" { emphasis.font = "Archivo" }
        case .heavy:
            emphasis.italic = nil
            emphasis.weight = 800
            emphasis.font = nil
        }
        set("caption.headline.emph", to: ScreenshotTemplate.encoded(emphasis))
    }

    var highlight: TemplateHighlight? { template?.caption.headline.highlight }

    func setHighlighted(_ isOn: Bool) {
        set("caption.headline.mark", to: isOn ? ScreenshotTemplate.encoded(highlight ?? Self.defaultHighlight) : .null)
    }

    func setHighlightColor(_ color: String) {
        guard var highlight else { return }
        highlight.color = color
        set("caption.headline.mark", to: ScreenshotTemplate.encoded(highlight))
    }
}
