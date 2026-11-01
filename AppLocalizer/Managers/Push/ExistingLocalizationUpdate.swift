//
//  ExistingLocalizationUpdate.swift
//  AppLocalizer
//

import Foundation

/// A new locale's `POST` that App Store Connect refused because the locale
/// is there by now: added in App Store Connect after the change was
/// queued, or created along with the other level's localization. Apple's
/// error says "Try updating", so Review & Push finds that localization and
/// `PATCH`es the same texts onto it, as long as that overwrites nothing:
/// each field is empty there or already has the text. Otherwise the change
/// isn't sent; the Store Page shows it as edits of what's there.
struct ExistingLocalizationUpdate: Hashable, Sendable {
    /// `appStoreVersionLocalizations` or `appInfoLocalizations`.
    var type: String
    var locale: String
    /// The texts the `POST` sets, without `locale`; nil clears a field.
    var attributes: [String: String?]
    /// The parent's localizations, e.g.
    /// `/v1/appStoreVersions/{id}/appStoreVersionLocalizations?limit=200`.
    var lookupPath: String

    /// The update a refused `POST` turns into, when it creates a Store Page
    /// localization.
    init?(_ request: PushRequest) {
        let types = [ListingChangeBuilder.versionLocalizationType, ListingChangeBuilder.appInfoLocalizationType]
        guard request.method == .post,
              let document = StorePageWriteDocument.decode(request.body),
              types.contains(document.data.type),
              request.path == "/v1/\(document.data.type)",
              let locale = document.attribute("locale"),
              let parent = document.data.relationships?.values.first?.data
        else { return nil }
        type = document.data.type
        self.locale = locale
        attributes = document.data.attributes.filter { $0.key != "locale" }
        lookupPath = "/v1/\(parent.type)/\(parent.id)/\(document.data.type)?limit=200"
    }

    /// The localization for `locale` in the lookup's response: its ID and
    /// the fields whose text there the update would overwrite. nil when
    /// it isn't there.
    func existing(in data: Data) -> (id: String, overwritten: [String])? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let resources = object["data"] as? [[String: Any]]
        else { return nil }
        for resource in resources {
            guard let id = resource["id"] as? String,
                  let current = resource["attributes"] as? [String: Any],
                  current["locale"] as? String == locale
            else { continue }
            let overwritten = attributes.compactMap { name, value -> String? in
                let text = current[name] as? String ?? ""
                return text.isEmpty || text == (value ?? "") ? nil : name
            }
            return (id, overwritten.sorted())
        }
        return nil
    }

    /// `PATCH /v1/<type>/<id>` with the texts; nil for a page created
    /// without text, which needs nothing more.
    func update(id: String) -> PushRequest? {
        guard !attributes.isEmpty else { return nil }
        return ListingChangeBuilder.patch(path: "/v1/\(type)/\(id)", type: type, id: id, attributes: attributes)
    }

    /// The localization is there with other text, so nothing was sent.
    func otherText(in fields: [String]) -> OtherTextError {
        OtherTextError(locale: locale, fields: fields)
    }

    /// Why a refused `POST` wasn't turned into an update: the push row's
    /// red line.
    struct OtherTextError: LocalizedError, Hashable, Sendable {
        var locale: String
        var fields: [String]

        var errorDescription: String? {
            let language = StoreLocaleCatalog.locale(code: locale)?.name ?? locale
            let titles = fields.map { ListingField(rawValue: $0)?.title ?? $0 }.formatted(.list(type: .and))
            return String(
                localized: "\(language) is already in App Store Connect with its own \(titles), so nothing was overwritten. Open the Store Page to review these as edits of what’s there."
            )
        }
    }
}
