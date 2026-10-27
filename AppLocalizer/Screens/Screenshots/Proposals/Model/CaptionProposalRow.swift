//
//  CaptionProposalRow.swift
//  AppLocalizer
//

import Foundation

/// One caption of a caption proposal as the sheet shows it: where it goes,
/// the caption it replaces, and both measured against the current
/// template.
struct CaptionProposalRow: Hashable, Sendable, Identifiable {
    var item: CaptionProposalItem
    /// "German · slot 2 · Week".
    var title: String
    /// The headline it replaces; nil when the slot has none.
    var currentHeadline: String?
    var currentFit: CaptionFit?
    var proposedFit: CaptionFit
    /// The render accepting it would make.
    var proposedPreview: SlotPreview

    var id: LocaleSlot { item.key }

    /// "Now · Fits at 112 u".
    var currentFitText: String {
        guard let currentFit, !currentFit.isEmpty else { return String(localized: "Now · No caption") }
        return String(localized: "Now · \(currentFit.label)")
    }

    /// "Proposed · Fits at 112 u".
    var proposedFitText: String {
        String(localized: "Proposed · \(proposedFit.label)")
    }
}
