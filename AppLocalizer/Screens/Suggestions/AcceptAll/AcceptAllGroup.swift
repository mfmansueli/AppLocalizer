//
//  AcceptAllGroup.swift
//  AppLocalizer
//

import Foundation

/// A language or a page in the Accept All sheet, with its suggestions.
struct AcceptAllGroup: Identifiable, Hashable, Sendable {
    /// A locale's code, or a page's raw value.
    let id: String
    var title: String
    /// The flag beside a language; pages have none.
    var regionCode: String?
    /// A language that isn't on the App Store yet.
    var isNewPage = false
    var isRightToLeft = false
    var items: [AcceptAllItem]
}
