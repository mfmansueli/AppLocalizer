//
//  ChangeOption.swift
//  AppLocalizer
//

import Foundation

/// A switch Review & Push shows under one change, e.g. "Publish to the App
/// Store" under an accessibility declaration. When it's on, its `requests`
/// are sent after the change's own; when it's off, only the change's own
/// go. The section that builds the change sets the default; the person flips
/// it in review, and the queue keeps the choice.
///
/// Generic on purpose: the review row, the footer and the progress list only
/// read the texts here, so any change can offer one.
struct ChangeOption: Hashable, Codable, Sendable {
    /// The switch's label, e.g. "Publish to the App Store".
    var title: String
    var isOn: Bool
    /// The line under the switch while it's on, e.g. "Goes on the product
    /// page as soon as it's pushed."
    var onNote: String
    /// The line under the switch while it's off, e.g. "Saved in App Store
    /// Connect as a draft."
    var offNote: String
    /// Why it can't be turned on, e.g. "Apple Vision Pro has no live version
    /// yet…". The switch shows off and disabled, and this replaces the note.
    var disabledReason: String?
    /// Sent after the change's own requests while the option is on.
    var requests: [PushRequest]
    /// The progress row while `requests` are being sent, e.g. "Publishing…".
    var progressTitle: String
    /// The progress row once done with the option on, e.g. "Published".
    var doneTitle: String
    /// The progress row once done with the option off, e.g. "Saved as a draft".
    var offDoneTitle: String
    /// What the review footer says about the changes that have it on, e.g.
    /// "2 declarations publish immediately when pushed".
    var footnote: ChangeOptionFootnote?

    var isEnabled: Bool { disabledReason == nil }

    /// On, and allowed to be: its requests go with the push.
    var isEffective: Bool { isOn && isEnabled }

    /// The line under the switch.
    var note: String { disabledReason ?? (isOn ? onNote : offNote) }

    /// What the progress list says once the change went through.
    var finishedTitle: String { isEffective ? doneTitle : offDoneTitle }
}
