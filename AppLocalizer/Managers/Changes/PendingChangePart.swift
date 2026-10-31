//
//  PendingChangePart.swift
//  AppLocalizer
//

import Foundation

/// One field a change writes when it writes several in one request, e.g.
/// the Polish name a new App Store language is created with. Review & Push
/// lists it under what's created, with who wrote it.
struct PendingChangePart: Identifiable, Hashable, Codable, Sendable {
    /// The field's key, e.g. `name` or `whatsNew`.
    var id: String
    /// "Name", "What’s New".
    var title: String
    var oldValue: String
    var newValue: String
    var source: ChangeSource
}
