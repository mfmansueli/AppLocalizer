//
//  StoreListing+Coverage.swift
//  AppLocalizer
//

import Foundation

extension StoreListing {
    /// The state one coverage cell or editor field shows.
    func coverageState(of field: ListingField, in locale: StoreLocale) -> ListingCoverageState {
        ListingCoverageState(
            draft: draft(field, in: locale),
            field: field,
            isEditable: canEdit(field),
            applies: applies(field)
        )
    }

    var coverage: ListingCoverageGrid {
        ListingCoverageGrid(self)
    }
}
