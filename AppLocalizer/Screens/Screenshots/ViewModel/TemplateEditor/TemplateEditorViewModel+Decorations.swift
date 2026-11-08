//
//  TemplateEditorViewModel+Decorations.swift
//  AppLocalizer
//

import Foundation

// Decorations · Slot N: the slot's shapes, laurels, badges and props. Every
// edit writes the slot's whole list as its override; a list back to the
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

    /// Hide or Show: a hidden decoration stays in the list, undrawn.
    func toggleDecorationHidden(at index: Int) {
        editDecoration(at: index) { $0.hidden = $0.isHidden ? nil : true }
    }

    /// "Figure · shared with slot 5", "Game controller", "Rating laurel".
    func decorationTitle(_ decoration: TemplateDecoration) -> String {
        guard let span = decoration.span else { return decoration.title }
        let other = span + 1
        return span > slot
            ? String(localized: "\(decoration.title) · shared with slot \(other)")
            : String(localized: "\(decoration.title) · continues from slot \(other)")
    }

    /// A laurel's or badge's value; the applier refuses letters.
    func setDecorationValue(_ value: String, at index: Int) {
        editDecoration(at: index) { $0.value = value.trimmingCharacters(in: .whitespaces) }
    }

    /// "4.8 ★ · 220 ratings in the United States": the App Store's rating
    /// a laurel shows in the editor's language, read daily; "No ratings in
    /// South Korea yet · hidden there" where it has none.
    var storeRatingLine: String {
        let country = StoreCountryName.phrase(locale.regionCode)
        switch screenshots.ratings.status(for: locale) {
        case let .rated(average):
            let value = String(format: "%.1f", (average * 10).rounded() / 10)
            guard let count = screenshots.ratings.count(inCountry: locale.regionCode) else {
                return String(localized: "\(value) ★ in \(country)")
            }
            return count == 1
                ? String(localized: "\(value) ★ · 1 rating in \(country)")
                : String(localized: "\(value) ★ · \(count.formatted()) ratings in \(country)")
        case .unrated:
            return String(localized: "No ratings in \(country) yet · hidden there")
        case .unknown:
            return String(localized: "Reading the App Store rating in \(country)…")
        }
    }

    /// Type It: the laurel shows a value typed by hand, starting from the
    /// one it shows now; it's checked against the App Store before push.
    func typeRating(at index: Int) {
        let shown: String? = if case let .rated(average) = screenshots.ratings.status(for: locale) {
            String(format: "%.1f", (average * 10).rounded() / 10)
        } else {
            nil
        }
        editDecoration(at: index) { decoration in
            decoration.source = .custom
            decoration.value = shown ?? decoration.value ?? "4.8"
        }
    }

    /// Use App Store: the laurel shows the App Store's rating in each
    /// country again.
    func useStoreRating(at index: Int) {
        editDecoration(at: index) { $0.source = nil }
    }

    /// "Ratings show only numbers and stars… against Lumen’s App Store
    /// rating in that country.", or what props are on a slot that has them.
    var ratingNote: String {
        if slotDecorations.contains(where: { $0.type == .art }) {
            return String(localized: """
            Props are vector stand-ins drawn by the template, never taken from your captures. Hide or remove any that don’t \
            fit your app. Props that would cover the caption in a language move below it or step aside on their own.
            """)
        }
        return String(
            localized: """
            Rating laurels show this app’s real App Store rating in each country, read daily from the App Store (average and \
            count per storefront); where the app has no ratings yet, the laurel is left out. Ratings show only numbers and \
            stars, so they need no translation. Type It sets a value by hand; before pushing, AppLocalizer checks it against \
            \(templateTitle)’s rating in that country, since Apple rejects misleading screenshots.
            """
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
