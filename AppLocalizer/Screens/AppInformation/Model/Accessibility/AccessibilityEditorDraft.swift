//
//  AccessibilityEditorDraft.swift
//  AppLocalizer
//

import Foundation

/// The editor sheet's state for one family: the Yes/No answer, the checked
/// features, and what they're compared with.
struct AccessibilityEditorDraft: Identifiable, Hashable, Sendable {
    var family: DeviceFamily
    /// Nil until Yes or No is chosen for a family never declared.
    var supportsAny: Bool?
    var features: Set<AccessibilityFeature>
    /// What's on the product page, for Live / Adds / Removes.
    var published: AccessibilityAnswer?
    var suggestions: [AccessibilitySuggestion] = []

    var id: DeviceFamily { family }

    init(card: AccessibilityCard, suggestions: [AccessibilitySuggestion] = []) {
        family = card.family
        published = card.published
        let shown = card.shown
        supportsAny = shown.map(\.supportsAny)
        features = shown?.features.intersection(card.family.features) ?? []
        self.suggestions = suggestions.filter { $0.feature.isAvailable(on: card.family) }
    }

    /// The features Apple asks about on this family.
    var availableFeatures: [AccessibilityFeature] { family.features }

    /// The answer Save queues, or nil while it can't be saved.
    var answer: AccessibilityAnswer? {
        switch supportsAny {
        case true?: features.isEmpty ? nil : AccessibilityAnswer(features: features)
        case false?: AccessibilityAnswer()
        case nil: nil
        }
    }

    /// Why Save is disabled.
    var saveBlocker: String? {
        switch supportsAny {
        case nil: String(localized: "Choose Yes or No first.")
        case true? where features.isEmpty: String(localized: "Check at least one feature, or answer No.")
        default: nil
        }
    }

    func isChecked(_ feature: AccessibilityFeature) -> Bool {
        features.contains(feature)
    }

    mutating func toggle(_ feature: AccessibilityFeature) {
        guard feature.isAvailable(on: family) else { return }
        if features.contains(feature) { features.remove(feature) } else { features.insert(feature) }
    }

    /// Live, Adds or Removes, against a published declaration.
    func status(of feature: AccessibilityFeature) -> AccessibilityRowStatus? {
        guard let published, supportsAny == true || published.supportsAny else { return nil }
        let checked = supportsAny == true && features.contains(feature)
        switch (published.features.contains(feature), checked) {
        case (true, true): return .live
        case (false, true): return .adds
        case (true, false): return .removes
        case (false, false): return nil
        }
    }

    func suggestion(for feature: AccessibilityFeature) -> AccessibilitySuggestion? {
        suggestions.first { $0.feature == feature }
    }

    /// Copy from iPhone: takes `source`'s answer, leaving out what this
    /// family doesn't have. Returns the features left out.
    @discardableResult
    mutating func copy(_ source: AccessibilityAnswer) -> [AccessibilityFeature] {
        supportsAny = source.supportsAny
        features = source.features.intersection(family.features)
        return source.orderedFeatures.filter { !$0.isAvailable(on: family) }
    }
}
