//
//  CannedCaptionTranslator.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// A translator for caption tests: "[fi] text" by default, a set answer
/// per target locale, an overlong answer for some locales, and languages
/// that act as not downloaded. It records what it was sent and never
/// reaches Apple.
struct CannedCaptionTranslator: ListingTranslator {
    /// The answer per target locale code, instead of "[code] text".
    var answers: [String: String] = [:]
    /// Target locale codes that get a caption far too long to fit.
    var overlong: Set<String> = []
    var availability: [String: TranslationAvailability] = [:]
    let sent = Sent()

    static let overlongText = "Ein außerordentlich langer Untertitel, der niemals in zwei Zeilen passt, egal wie klein die Schrift gesetzt wird"

    func availability(from _: StoreLocale, to target: StoreLocale) async -> TranslationAvailability {
        availability[target.code] ?? .ready
    }

    func translate(_ text: String, field _: ListingField, from _: StoreLocale, to target: StoreLocale) async throws -> String {
        sent.append(text)
        if overlong.contains(target.code) { return Self.overlongText }
        return answers[target.code] ?? "[\(target.code)] \(text)"
    }

    /// The texts handed to the translator, in order.
    final class Sent: Sendable {
        private let storage = Mutex<[String]>([])

        var texts: [String] { storage.withLock { $0 } }

        func append(_ text: String) {
            storage.withLock { $0.append(text) }
        }
    }
}
