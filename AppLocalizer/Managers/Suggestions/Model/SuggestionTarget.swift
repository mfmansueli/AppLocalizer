//
//  SuggestionTarget.swift
//  AppLocalizer
//

import Foundation

/// The one field a suggestion is for: a scope and the field's key there,
/// e.g. German keywords (`store.de-DE.keywords`) or App Review's notes
/// (`info.appReview.notes`). Store Page keys are `ListingField` raw values;
/// App Information keys are `AppInformationSuggestionField` raw values.
struct SuggestionTarget: Hashable, Codable, Sendable {
    var scope: SuggestionScope
    var field: String

    init(_ scope: SuggestionScope, field: String) {
        self.scope = scope
        self.field = field
    }

    var id: String { "\(scope.id).\(field)" }

    static func storePage(_ locale: StoreLocale, _ field: ListingField) -> SuggestionTarget {
        SuggestionTarget(.storePage(locale), field: field.rawValue)
    }

    static func appInformation(_ field: AppInformationSuggestionField) -> SuggestionTarget {
        SuggestionTarget(.appInformation(field.page), field: field.rawValue)
    }
}
