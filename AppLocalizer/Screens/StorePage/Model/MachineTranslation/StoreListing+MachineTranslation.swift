//
//  StoreListing+MachineTranslation.swift
//  AppLocalizer
//

import Foundation

extension StoreListing {
    /// The machine-translation tags to keep for fields at `level`:
    /// `ListingFieldKey.id` → the tagged text.
    func machineTranslationTags(at level: ListingFieldLevel) -> [String: String] {
        var tags: [String: String] = [:]
        for locale in locales {
            for field in ListingField.allCases where field.level == level {
                let draft = draft(field, in: locale)
                if draft.isMachineTranslated, !draft.local.isEmpty {
                    tags[ListingFieldKey(locale, field).id] = draft.local
                }
            }
        }
        return tags
    }

    /// Fields tagged machine-translated in `locale`, for "Mark All Reviewed".
    func machineTranslatedFields(in locale: StoreLocale) -> [ListingField] {
        fields.filter { draft($0, in: locale).isMachineTranslated }
    }
}
