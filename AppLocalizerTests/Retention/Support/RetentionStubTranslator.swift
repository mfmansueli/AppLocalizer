//
//  RetentionStubTranslator.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Translates by tagging the text with the target's code ("[de-DE] Stay"),
/// or with `long` repeated for `longTarget`; `missing` languages need a
/// download first.
struct RetentionStubTranslator: ListingTranslator {
    var longTarget: String?
    var missing: Set<String> = []

    func availability(from _: StoreLocale, to target: StoreLocale) async -> TranslationAvailability {
        missing.contains(target.code) ? .needsDownload : .ready
    }

    func translate(_ text: String, field _: ListingField, from _: StoreLocale, to target: StoreLocale) async throws -> String {
        if target.code == longTarget { return String(repeating: "lang ", count: 40) }
        return "[\(target.code)] \(text)"
    }
}
