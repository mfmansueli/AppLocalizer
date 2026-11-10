//
//  AppInformationPageBarModel.swift
//  AppLocalizer
//

import Foundation

/// What the bar under an App Information page's title says: how many wait
/// here and on the other pages.
struct AppInformationPageBarModel: Equatable, Sendable {
    var hereCount: Int
    var totalCount: Int
    /// Other pages with suggestions.
    var otherPageCount: Int
    /// "Don't ask again" is on: Accept All Pages accepts at once.
    var acceptsRightAway = false

    var acceptHereTitle: String {
        String(localized: "Accept \(hereCount) on This Page")
    }

    var acceptAllTitle: String {
        totalCount > 0 ? String(localized: "Accept All Pages") : String(localized: "All Pages Reviewed")
    }

    /// "12 more on 3 other pages".
    var restText: String {
        let rest = totalCount - hereCount
        if rest > 0 {
            return otherPageCount == 1
                ? String(localized: "\(rest) more on 1 other page")
                : String(localized: "\(rest) more on \(otherPageCount) other pages")
        }
        return totalCount > 0 ? String(localized: "Only this page has suggestions") : String(localized: "Every page is reviewed")
    }

    var acceptAllAccessibilityText: String {
        guard totalCount > 0 else { return String(localized: "Every page is reviewed") }
        let how = acceptsRightAway ? String(localized: "accepts right away") : String(localized: "shows them first")
        return String(localized: "Accept all pages: \(totalCount) suggestions, \(how)")
    }
}
