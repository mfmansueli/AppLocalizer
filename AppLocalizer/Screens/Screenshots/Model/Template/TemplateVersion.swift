//
//  TemplateVersion.swift
//  AppLocalizer
//

import Foundation

/// One saved version of the template, as the History popover lists it:
/// number, date, author and note. A version from an accepted proposal is
/// authored by the assistant (`ChangeSource.assistant`), which is what puts
/// the CC tag on it.
struct TemplateVersion: Codable, Hashable, Sendable, Identifiable {
    var template: ScreenshotTemplate
    var date: Date
    var author: ChangeSource
    var note: String
    /// The version this one restored, for "Restored v2".
    var restoredFrom: Int?

    var number: Int { template.version }
    var id: Int { number }

    /// The assistant that proposed this version, if one did.
    var assistant: String? {
        if case let .assistant(client) = author { return client }
        return nil
    }
}
