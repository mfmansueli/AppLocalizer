//
//  PendingCreation.swift
//  AppLocalizer
//

import Foundation

/// What a change creates in App Store Connect, for Review & Push: a new App
/// Store language, "Create the Polish page", with the fields it's created
/// with. A language takes up to two writes (its app information and its
/// version text), so changes with the same `id` show as one row with every
/// field under it, and the fields go with it: they can't be pushed on their
/// own.
struct PendingCreation: Hashable, Codable, Sendable {
    /// The same for every change that creates the same thing, e.g.
    /// `storePage.<appID>.pl`.
    var id: String
    /// "Create the Polish page".
    var title: String
    /// "A new App Store language for Lumen Journal, with the text below".
    var detail: String
    /// Who suggested creating it: Built-in for a language the app's project
    /// has, else You.
    var source: ChangeSource
    /// The fields this change creates it with, in the editor's order.
    var fields: [PendingChangePart]
}
