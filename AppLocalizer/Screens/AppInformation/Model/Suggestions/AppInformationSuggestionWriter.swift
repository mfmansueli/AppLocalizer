//
//  AppInformationSuggestionWriter.swift
//  AppLocalizer
//

import Foundation

/// Turns a value for one `AppInformationSuggestionField` into the change
/// that queues it, as the page's own edits do but tagged with who
/// suggested it. Accepting a suggestion on the page and `suggest_fields`
/// with `apply` both write through it.
enum AppInformationSuggestionWriter {
    /// What a change is built from: App Store Connect's content, the values
    /// shown (with queued changes on top), and the builder for the version.
    struct Values {
        var content: AppInformationContent
        var general: GeneralValues
        var review: AppReviewValues
        var builder: AppInformationChangeBuilder
    }

    /// The change for `field` set to `value` (as stored: a category or
    /// release option by id) and the id it's queued under. The change is
    /// nil when the field is back at App Store Connect's value; the whole
    /// result is nil when the field can't take it (the version is locked, or
    /// "On a date" without a date).
    static func change(
        _ field: AppInformationSuggestionField,
        to value: String,
        in values: Values,
        source: ChangeSource
    ) -> (change: PendingChange?, id: String)? {
        typealias Key = AppInformationChangeBuilder.GeneralKey
        let (content, general, review, builder) = (values.content, values.general, values.review, values.builder)
        if field.isVersionLevel, !content.isVersionEditable { return nil }
        switch field {
        case .copyright:
            return (builder.copyrightChange(from: content.general.copyright, to: value, source: source), builder.versionChangeID(.general, Key.copyright))
        case .primaryCategory, .secondaryCategory:
            let key = field == .primaryCategory ? Key.primaryCategory : Key.secondaryCategory
            let old = field == .primaryCategory ? content.general.primaryCategory : content.general.secondaryCategory
            return (builder.categoryChange(key, from: old, to: value.isEmpty ? nil : value, source: source), builder.changeID(.general, key))
        case .release:
            guard let option = ReleaseOption(rawValue: value) else { return nil }
            let date = general.earliestReleaseDate
            if option == .scheduled, date == nil { return nil }
            let old = (content.general.release, content.general.earliestReleaseDate)
            return (builder.releaseChange(from: old, to: (option, date), source: source), builder.versionChangeID(.general, Key.release))
        case .contactFirstName, .contactLastName, .contactPhone, .contactEmail, .notes:
            guard let reviewField = field.reviewField else { return nil }
            var edited = review
            edited.setText(value, for: reviewField)
            if content.ids.reviewDetailID == nil {
                return (builder.newReviewDetailChange(edited, source: source), builder.newReviewDetailChangeID)
            }
            return (builder.reviewFieldChange(reviewField, from: content.review, to: edited, source: source), builder.reviewChangeID(reviewField))
        }
    }
}
