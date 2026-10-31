//
//  ListingChangeBuilder+Reading.swift
//  AppLocalizer
//

import Foundation

extension ListingChangeBuilder {
    /// Lays queued changes onto a listing that has App Store Connect's
    /// values: each change's request body says which fields get which text.
    /// A text whose machine-translation tag matches (`machineTranslated`,
    /// `ListingFieldKey.id` → text) stays tagged; an assistant's change is a
    /// proposal; an accepted built-in or AI provider suggestion keeps its
    /// source; anything else is your edit. A new language's fields each keep
    /// their own source (`PendingChange.creation`), and the language shows
    /// even before it has text. An assistant's alternative to your change
    /// becomes a conflict on the field.
    func apply(_ changes: [PendingChange], to listing: inout StoreListing, machineTranslated: [String: String] = [:]) {
        for change in changes {
            guard let level = level(of: change),
                  let document = StorePageWriteDocument.decode(change.requests.first?.body),
                  let locale = locale(of: change, document: document, level: level)
            else { continue }
            if change.creation != nil { listing.addLocale(locale) }
            for (field, text) in Self.texts(in: document, at: level) {
                let key = ListingFieldKey(locale, field)
                let source = change.creation?.fields.first { $0.id == field.rawValue }?.source ?? change.source
                listing.update(field, in: locale) { draft in
                    if !text.isEmpty, machineTranslated[key.id] == text {
                        draft.acceptMachineTranslation(text)
                    } else if case let .assistant(client) = source {
                        _ = draft.propose(text, by: client)
                    } else if source == .builtInSuggestion || source == .aiProvider {
                        draft.acceptSuggestion(text, from: source)
                    } else {
                        draft.edit(text)
                    }
                }
            }
            applyAlternative(of: change, to: &listing, locale: locale, level: level)
        }
    }

    private func applyAlternative(of change: PendingChange, to listing: inout StoreListing, locale: StoreLocale, level: ListingFieldLevel) {
        guard let alternative = change.alternative,
              case let .assistant(client) = alternative.source,
              let document = StorePageWriteDocument.decode(alternative.requests.first?.body)
        else { return }
        for (field, text) in Self.texts(in: document, at: level) {
            listing.update(field, in: locale) { _ = $0.propose(text, by: client) }
        }
    }

    /// A new locale's code is in its body; a field change's is in its id.
    private func locale(of change: PendingChange, document: StorePageWriteDocument, level: ListingFieldLevel) -> StoreLocale? {
        if let code = document.attribute("locale") { return StoreLocaleCatalog.locale(code: code) }
        let rest = change.id.dropFirst(idPrefix(at: level).count)
        guard let code = rest.split(separator: ".").first else { return nil }
        return StoreLocaleCatalog.locale(code: String(code))
    }

    /// The listing fields a write sets, with their text ("" for `null`).
    private static func texts(in document: StorePageWriteDocument, at level: ListingFieldLevel) -> [(ListingField, String)] {
        document.data.attributes.compactMap { name, value in
            guard let field = ListingField(rawValue: name), field.level == level else { return nil }
            return (field, value ?? "")
        }
        .sorted { $0.0.rawValue < $1.0.rawValue }
    }
}
