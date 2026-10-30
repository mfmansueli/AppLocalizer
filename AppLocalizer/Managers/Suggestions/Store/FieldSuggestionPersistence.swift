//
//  FieldSuggestionPersistence.swift
//  AppLocalizer
//

import Foundation

/// Where suggestions and the decisions about them are kept between
/// launches. `FileFieldSuggestionPersistence` is the real one; tests and
/// DEBUG scenes keep them in memory (pass nil).
protocol FieldSuggestionPersistence: Sendable {
    func load() throws -> FieldSuggestionArchive
    func save(_ archive: FieldSuggestionArchive) throws
}
