//
//  TemplateEditorViewModel+Decorations.swift
//  AppLocalizer
//

import Foundation

// Decorations · Slot N: the slot's shapes, laurels and badges. Every edit
// writes the slot's whole list as its override; a list back to the
// template's own clears it.
extension TemplateEditorViewModel {
    /// What Add Rating, Add Sparkle, Add Shape and Add Badge put on the
    /// slot.
    enum DecorationPreset: String, CaseIterable, Identifiable {
        case rating
        case sparkle
        case shape
        case badge

        var id: String { rawValue }

        var title: String {
            switch self {
            case .rating: String(localized: "Add Rating")
            case .sparkle: String(localized: "Add Sparkle")
            case .shape: String(localized: "Add Shape")
            case .badge: String(localized: "Add Badge")
            }
        }

        /// Ratings and sparkles take the caption's color.
        func decoration(ink: String) -> TemplateDecoration {
            switch self {
            case .rating: .laurel(x: 0.3, y: 0.78, width: 0.4, color: ink, value: "4.8")
            case .sparkle: .shape(.sparkle, x: 0.82, y: 0.3, width: 0.1, color: ink, layer: .front)
            case .shape: .shape(.blob, x: 0.6, y: 0.3, width: 0.55, color: "#FFFFFF", layer: .back, opacity: 0.9)
            case .badge: .badge(x: 0.06, y: 0.78, width: 0.28, color: "#111111", ink: "#FFFFFF", value: "4.8 ★", rotation: -12)
            }
        }
    }

    /// "Decorations · Slot 3".
    var decorationsTitle: String {
        String(localized: "Decorations · Slot \(slot + 1)")
    }

    /// The decorations this slot draws: its own, else the template's.
    var slotDecorations: [TemplateDecoration] {
        slotTemplate?.decorations ?? []
    }

    func addDecoration(_ preset: DecorationPreset) {
        setSlotDecorations(slotDecorations + [preset.decoration(ink: slotInk)])
    }

    func removeDecoration(at index: Int) {
        var decorations = slotDecorations
        guard decorations.indices.contains(index) else { return }
        decorations.remove(at: index)
        setSlotDecorations(decorations)
    }

    func setDecorationColor(_ color: String, at index: Int) {
        editDecoration(at: index) { $0.color = color }
    }

    /// A laurel's or badge's value; the applier refuses letters.
    func setDecorationValue(_ value: String, at index: Int) {
        editDecoration(at: index) { $0.value = value.trimmingCharacters(in: .whitespaces) }
    }

    /// "Ratings show only numbers and stars… against Lumen’s App Store
    /// rating in that country."
    var ratingNote: String {
        String(
            localized: "Ratings show only numbers and stars, so they need no translation. Keep them true: before pushing, AppLocalizer checks each one against \(templateTitle)’s App Store rating in that country."
        )
    }

    private func editDecoration(at index: Int, _ change: (inout TemplateDecoration) -> Void) {
        var decorations = slotDecorations
        guard decorations.indices.contains(index) else { return }
        change(&decorations[index])
        setSlotDecorations(decorations)
    }

    private func setSlotDecorations(_ decorations: [TemplateDecoration]) {
        let own = template?.decorations ?? []
        setSlotOverride("deco", to: decorations == own ? nil : ScreenshotTemplate.encoded(decorations))
    }
}
