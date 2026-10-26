//
//  StorePageSheet.swift
//  AppLocalizer
//

import Foundation

/// The sheets the Store Page opens over its content.
enum StorePageSheet: String, Identifiable, Hashable, Sendable {
    /// "Translate missing fields".
    case translate
    /// "Find and replace across locales" (⌥⌘F).
    case findReplace
    /// "Import translations": the diff of a chosen file.
    case importPreview

    var id: String { rawValue }
}
