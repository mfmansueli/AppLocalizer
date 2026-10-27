//
//  FakeListingTranslator.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// A `ListingTranslator` that answers "[de-DE] <text>", so tests can see
/// what was sent, with per-language availability and fields that fail.
struct FakeListingTranslator: ListingTranslator {
    var availability: [StoreLocale: TranslationAvailability] = [:]
    var failing: Set<ListingFieldKey> = []
    /// Recorded texts, to check glossary terms were protected.
    let sent = SentTexts()

    func availability(from _: StoreLocale, to target: StoreLocale) async -> TranslationAvailability {
        availability[target] ?? .ready
    }

    func translate(_ text: String, field: ListingField, from _: StoreLocale, to target: StoreLocale) async throws -> String {
        sent.append(text)
        if failing.contains(ListingFieldKey(target, field)) { throw URLError(.cannotConnectToHost) }
        return "[\(target.code)] \(text)"
    }

    /// The texts handed to the translator, in order.
    final class SentTexts: Sendable {
        private let storage = Mutex<[String]>([])

        var texts: [String] { storage.withLock { $0 } }

        func append(_ text: String) {
            storage.withLock { $0.append(text) }
        }
    }
}
