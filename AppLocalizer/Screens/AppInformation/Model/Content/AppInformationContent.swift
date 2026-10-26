//
//  AppInformationContent.swift
//  AppLocalizer
//

import Foundation

/// App Information as App Store Connect has it, for one app and version:
/// what General, Age Rating, App Review and Export Compliance show before
/// pending changes are laid on top. Accessibility loads on its own
/// (`AccessibilityContent`).
struct AppInformationContent: Hashable, Sendable {
    var versions: [StorePageVersion]
    /// The version copyright, release, App Review and export compliance
    /// belong to; nil when the app has no version yet.
    var version: StorePageVersion?
    var ids: AppInformationResourceIDs
    var general: GeneralValues
    var ageRating: AgeRatingValues
    var review: AppReviewValues
    var export: ExportComplianceValues

    /// The newest version that can still change.
    var editableVersion: StorePageVersion? { versions.first(where: \.isEditable) }

    /// Version-level values can change: the version isn't live or in review.
    var isVersionEditable: Bool { version?.isEditable ?? false }
}
