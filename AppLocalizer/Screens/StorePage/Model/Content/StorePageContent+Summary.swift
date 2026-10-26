//
//  StorePageContent+Summary.swift
//  AppLocalizer
//

import Foundation

extension StorePageContent {
    /// The overview card's and sidebar's numbers: App Store Connect's texts
    /// with this Mac's machine-translation tags. Pending edits aren't
    /// counted; they show in the Store Page itself.
    func summary(machineTranslated: [String: String] = [:]) -> StorePageSummary {
        let coverage = listing(machineTranslated: machineTranslated).coverage.summary
        return StorePageSummary(
            versionString: version.versionString,
            versionState: version.state.title,
            hasEditableVersion: editableVersion != nil,
            localeCount: coverage.localeCount,
            totalLocaleCount: coverage.catalogCount,
            completeness: coverage.completeness,
            missingCount: coverage.missingCount,
            machineTranslatedCount: coverage.machineTranslatedCount,
            overLimitCount: coverage.overLimitCount
        )
    }
}
