//
//  ProposalStressColumn.swift
//  AppLocalizer
//

import Foundation

/// One locale of a template proposal's before-and-after strip: the slot
/// laid out from the current template and from the one accepting saves.
struct ProposalStressColumn: Hashable, Sendable, Identifiable {
    var locale: StoreLocale
    /// "English (U.S.) · Primary".
    var title: String
    var before: SlotPreview
    /// Nil when the proposal can't be applied.
    var after: SlotPreview?

    var id: String { locale.code }
}
