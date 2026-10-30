//
//  StorePageViewModel+KeyAssistant.swift
//  AppLocalizer
//

import Foundation

// Generate Suggestions… with an API key: the listing's text, plus the
// project folder's commits and changelog and the app's reviews when the
// person allowed them. What comes back is checked like an edit and goes
// into the suggestion store, tagged with the key's API.
extension StorePageViewModel: KeyAssistantGenerating {
    /// One page of App Store Connect's newest reviews.
    static let generatedReviewLimit = 200

    func keyAssistantPlan(using keyAssistant: KeyAssistantController) async -> KeyAssistantPlan? {
        guard tracksSuggestions, let listing, let configuration = keyAssistant.configuration else { return nil }
        let folder = await keyAssistant.readProjectFolder(version: listing.version.versionString)
        var reviews: [CustomerReview]?
        var notes: [String] = []
        if configuration.readsReviews {
            do {
                reviews = try await services.customerReviews(for: app, limit: Self.generatedReviewLimit)
            } catch {
                notes.append(String(localized: "Reviews couldn’t be read, so they aren’t sent: \(error.localizedDescription)"))
            }
        }
        var plan = KeyAssistantStorePrompt.plan(
            listing: listing,
            context: KeyAssistantStorePrompt.Context(folder: folder?.excerpt, folderPath: folder?.path, reviews: reviews)
        )
        plan.notes += notes
        return plan
    }

    func addGeneratedSuggestions(_ items: [KeyAssistantSuggestionItem], client: String) -> Int {
        guard tracksSuggestions, let listing else { return 0 }
        var added = 0
        for item in items {
            guard let field = ListingField.matching(item.field), KeyAssistantStorePrompt.fields.contains(field),
                  let locale = StoreLocaleCatalog.locale(code: item.locale), listing.contains(locale), listing.canEdit(field),
                  ListingFieldValidator.validate(item.value, for: field) == .valid, listing.value(field, in: locale) != item.value
            else { continue }
            let outcome = suggestions.add(
                appID: app.id,
                target: .storePage(locale, field),
                value: item.value,
                reason: item.reason ?? "",
                source: .assistant(client: client)
            ).outcome
            if outcome != .unchanged { added += 1 }
        }
        return added
    }
}
