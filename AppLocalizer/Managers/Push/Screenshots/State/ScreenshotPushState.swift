//
//  ScreenshotPushState.swift
//  AppLocalizer
//

import Foundation

/// What Review & Push remembers about one app's screenshots between
/// launches, besides the document: renders discarded to keep what's live,
/// and restores waiting to be pushed.
struct ScreenshotPushState: Codable, Hashable, Sendable {
    /// Discarded renders by cell: the render key that was discarded. A
    /// cell comes back to review as soon as its render key changes.
    var kept: [ScreenshotCellKey: RenderKey] = [:]
    var restores: [ScreenshotRestoreRequest] = []
    /// Kept screenshots discarded from a queued restore, by backup image
    /// ID: they stay out of the push until Undo.
    var keptRestores: Set<String> = []

    var isEmpty: Bool { kept.isEmpty && restores.isEmpty && keptRestores.isEmpty }

    func restore(for locale: String) -> ScreenshotRestoreRequest? {
        restores.first { $0.locale == locale }
    }

    /// Queues `request`, replacing an earlier one for the same locale.
    mutating func queue(_ request: ScreenshotRestoreRequest) {
        removeRestore(for: request.locale)
        restores.append(request)
    }

    /// Drops a locale's restore and its discards.
    mutating func removeRestore(for locale: String) {
        let images = Set(restores.filter { $0.locale == locale }.flatMap(\.images).map(\.id))
        keptRestores.subtract(images)
        restores.removeAll { $0.locale == locale }
    }

    /// Drops restores for locales that went back to the template (Use
    /// Template Again unpinned them). Returns whether anything changed.
    mutating func pruneRestores(keeping isPinned: (String) -> Bool) -> Bool {
        let unpinned = restores.map(\.locale).filter { !isPinned($0) }
        for locale in unpinned { removeRestore(for: locale) }
        return !unpinned.isEmpty
    }
}
