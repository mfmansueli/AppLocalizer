//
//  RetentionModel+Translation.swift
//  AppLocalizer
//

import Foundation

extension RetentionModel {
    var isTranslating: Bool { translatingLocale != nil }

    /// The languages Translate All fills in: every one but the source
    /// that's empty, and, once the source changed, the ones translated
    /// before. What someone wrote by hand stays.
    func languagesToTranslate(in message: RetentionMessage) -> [StoreLocale] {
        let redo = sourceEdited.contains(message.id)
        return builder.languages(of: message).filter { locale in
            guard locale.code != sourceLocale.code else { return false }
            let text = message.text(for: locale.code)
            if text.isEmpty { return true }
            if case .translated = text.origin { return redo }
            return false
        }
    }

    /// Whether Translate All has something to do.
    var canTranslate: Bool {
        guard let message = selectedMessage, !isTranslating else { return false }
        return message.text(for: sourceLocale.code).isComplete && !languagesToTranslate(in: message).isEmpty
    }

    /// Translates the source's header and message into every language
    /// that needs it, with `translator` (Settings → Translation's), and
    /// flags the ones that run over 66 or 144.
    func translateAll(with translator: any ListingTranslator, protector: GlossaryProtector) async {
        guard let message = selectedMessage, canTranslate else { return }
        let source = message.text(for: sourceLocale.code)
        var skipped: [String] = []
        var failed: [String] = []
        var done = 0
        for locale in languagesToTranslate(in: message) {
            translatingLocale = locale.code
            if await translator.availability(from: sourceLocale, to: locale) != .ready {
                skipped.append(locale.name)
                continue
            }
            do {
                let text = try await translate(source, to: locale, with: translator, protector: protector)
                guard selectedMessageID == message.id else { break }
                edit { $0.texts[locale.code] = text }
                done += 1
            } catch {
                failed.append(locale.name)
            }
        }
        translatingLocale = nil
        if failed.isEmpty, skipped.isEmpty { sourceEdited.remove(message.id) }
        notice = translationSummary(done: done, skipped: skipped, failed: failed)
    }

    private func translate(
        _ source: RetentionText,
        to locale: StoreLocale,
        with translator: any ListingTranslator,
        protector: GlossaryProtector
    ) async throws -> RetentionText {
        let header = protector.protect(RetentionText.trimmed(source.header))
        let body = protector.protect(RetentionText.trimmed(source.body))
        let translatedHeader = try await translator.translate(header.text, field: .promotionalText, from: sourceLocale, to: locale)
        let translatedBody = try await translator.translate(body.text, field: .promotionalText, from: sourceLocale, to: locale)
        return RetentionText(header: header.restore(translatedHeader), body: body.restore(translatedBody), origin: .translated)
    }

    /// "Translated 17 languages. German runs over 144 characters."
    private func translationSummary(done: Int, skipped: [String], failed: [String]) -> String {
        var parts = [done == 1 ? String(localized: "Translated 1 language.") : String(localized: "Translated \(done) languages.")]
        if let message = selectedMessage {
            let tooLong = builder.languages(of: message).filter { message.text(for: $0.code).isTooLong }.map(\.name)
            if !tooLong.isEmpty {
                parts.append(String(localized: "\(tooLong.formatted(.list(type: .and))) run over Apple’s limits; shorten them before you push."))
            }
        }
        if !skipped.isEmpty {
            parts.append(String(localized: "\(skipped.formatted(.list(type: .and))) need a download in Apple Translation first."))
        }
        if !failed.isEmpty { parts.append(String(localized: "\(failed.formatted(.list(type: .and))) didn’t translate; try again.")) }
        return parts.joined(separator: " ")
    }
}
