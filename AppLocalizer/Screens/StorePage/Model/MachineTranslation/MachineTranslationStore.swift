//
//  MachineTranslationStore.swift
//  AppLocalizer
//

import Foundation

/// Which texts are accepted machine translation nobody has reviewed yet.
/// App Store Connect doesn't keep that, so this Mac does, per app and per
/// scope (`MachineTranslationScope`), as `ListingFieldKey.id` → the text
/// that was accepted. A tag only counts while the field still has that
/// exact text, so any edit, here or in App Store Connect, clears it.
@MainActor
protocol MachineTranslationStore: AnyObject {
    func tags(appID: StoreApp.ID, scope: String) -> [String: String]
    /// Replaces the scope's tags; an empty dictionary forgets the scope.
    func setTags(_ tags: [String: String], appID: StoreApp.ID, scope: String)
}
