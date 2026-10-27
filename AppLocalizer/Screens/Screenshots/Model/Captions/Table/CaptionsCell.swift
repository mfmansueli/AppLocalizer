//
//  CaptionsCell.swift
//  AppLocalizer
//

import Foundation

/// One caption in the Captions table (design README §2 "Captions"): its
/// text, how it fits the template on the current display type, and its
/// tags.
struct CaptionsCell: Hashable, Sendable, Identifiable {
    var key: LocaleSlot
    var caption: ScreenshotCaption?
    /// Nil without a template.
    var fit: CaptionFit?
    var isPrimary: Bool
    /// The subhead shows on hero slots only.
    var showsSubhead: Bool
    /// An assistant's proposal for this caption waits in Review.
    var proposalClient: String?

    var id: LocaleSlot { key }

    var isMissing: Bool { caption == nil }

    /// "Write caption" for the primary locale, "Missing" elsewhere.
    var missingTitle: String {
        isPrimary ? String(localized: "Write caption") : String(localized: "Missing")
    }

    var isOverflowing: Bool { fit?.tone == .overflows }

    var isMachineTranslated: Bool { caption?.provenance.isMachineTranslated == true }

    /// A translation someone changed: the edited dot.
    var isEdited: Bool { !isPrimary && caption?.provenance.isEdited == true }

    /// The CC tag: the caption came from an assistant, or one proposed a
    /// change to it.
    var assistant: String? {
        if case let .assistant(client, _)? = caption?.provenance { return client }
        return proposalClient
    }

    /// The Needs attention filter: missing, overflowing or machine text.
    var needsAttention: Bool { isMissing || isOverflowing || isMachineTranslated }

    /// The fit label, or "No template yet".
    var fitLabel: String {
        fit?.label ?? String(localized: "No template yet")
    }

    /// For VoiceOver: "German slot 3: Durchsuche…, 1 line too many at 80 u".
    func accessibilityText(localeName: String) -> String {
        guard let caption else { return String(localized: "\(localeName) slot \(key.slot + 1): \(missingTitle)") }
        return String(localized: "\(localeName) slot \(key.slot + 1): \(caption.headline), \(fitLabel)")
    }
}
