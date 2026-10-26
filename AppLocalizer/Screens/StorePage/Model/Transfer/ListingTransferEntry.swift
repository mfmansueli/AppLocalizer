//
//  ListingTransferEntry.swift
//  AppLocalizer
//

import Foundation

/// One value read from an imported file, exactly as written there. Locale
/// codes and field names are matched later, so unknown ones can be listed
/// as problems.
struct ListingTransferEntry: Hashable, Sendable {
    let localeCode: String
    let fieldName: String
    let value: String
}
