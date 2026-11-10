//
//  AppInformationViewModel+AcceptAll.swift
//  AppLocalizer
//

import Foundation

// The page bar: how many suggestions wait on each page, Accept n on This
// Page, and Accept All Pages, which shows them first unless the person said
// not to.
extension AppInformationViewModel {
    /// Every page's suggestions, in the page column's order.
    private var allPageSuggestions: [FieldSuggestion] {
        Self.suggestionPages.flatMap { visibleSuggestions(on: $0) }
    }

    func pageBarModel(on page: AppInformationPage, acceptsRightAway: Bool) -> AppInformationPageBarModel {
        let others = Self.suggestionPages.filter { $0 != page && !visibleSuggestions(on: $0).isEmpty }
        return AppInformationPageBarModel(
            hereCount: visibleSuggestions(on: page).count,
            totalCount: allPageSuggestions.count,
            otherPageCount: others.count,
            acceptsRightAway: acceptsRightAway
        )
    }

    /// "7 suggested · 7 unanswered", "Exempt · done", "Up to date": a page's
    /// status in the page column, when its suggestions and answers say it.
    func pageColumnStatus(for page: AppInformationPage) -> String? {
        let suggested = suggestionCount(on: page)
        let unanswered = unansweredCount(on: page)
        if suggested > 0 {
            return unanswered > 0
                ? String(localized: "\(suggested) suggested · \(unanswered) unanswered")
                : String(localized: "\(suggested) suggested")
        }
        if unanswered > 0 { return String(localized: "\(unanswered) unanswered") }
        switch page {
        case .appPrivacy: return status(for: page)
        case .exportCompliance:
            guard let status = status(for: page) else { return nil }
            return exportAnswers?.usesNonExemptEncryption == false ? String(localized: "\(status) · done") : status
        case .general, .ageRating, .accessibility, .appReview:
            return isPageLoaded(page) ? String(localized: "Up to date") : nil
        }
    }

    /// The green check beside a page: nothing to decide and nothing missing.
    func isPageUpToDate(_ page: AppInformationPage) -> Bool {
        guard page != .appPrivacy, isPageLoaded(page) else { return false }
        if page == .exportCompliance { return exportAnswers?.usesNonExemptEncryption != nil }
        return suggestionCount(on: page) == 0 && unansweredCount(on: page) == 0
    }

    private func isPageLoaded(_ page: AppInformationPage) -> Bool {
        page == .accessibility ? accessibility.value != nil : isLoaded
    }

    private func unansweredCount(on page: AppInformationPage) -> Int {
        guard page == .ageRating, isLoaded else { return 0 }
        return AgeRatingQuestion.allCases.count { suggestionValue(.ageRating($0)).isEmpty }
    }

    /// What Accept All Pages offers, the open page first in focus.
    func acceptAllSelection() -> AcceptAllSelection {
        let groups = Self.suggestionPages.compactMap { page -> AcceptAllGroup? in
            let items = visibleSuggestions(on: page).compactMap { suggestion -> AcceptAllItem? in
                guard let slot = slot(of: suggestion) else { return nil }
                var title = slot.title
                if case let .accessibility(family, _) = slot { title = "\(family.name) · \(title)" }
                return AcceptAllItem(
                    id: suggestion.id,
                    title: title,
                    source: suggestion.source,
                    current: slot.displayValue(suggestionValue(slot)),
                    suggested: slot.displayValue(suggestion.value),
                    reason: suggestion.reason
                )
            }
            guard !items.isEmpty else { return nil }
            return AcceptAllGroup(id: page.rawValue, title: page.title, items: items)
        }
        return AcceptAllSelection(kind: .appInformation, groups: groups, focus: page.rawValue)
    }

    /// "Accept n on This Page".
    func acceptSuggestions(onPage page: AppInformationPage) {
        let batch = visibleSuggestions(on: page)
        let text = batch.count == 1
            ? String(localized: "Accepted 1 on \(page.title). It’s in Review & Push.")
            : String(localized: "Accepted \(batch.count) on \(page.title). They’re in Review & Push.")
        accept(batch, toast: text)
    }

    /// The bar's button: right away when the person said not to ask,
    /// otherwise the sheet.
    func acceptAllPages(withoutAsking: Bool) {
        guard withoutAsking else {
            isAcceptAllPresented = true
            return
        }
        let batch = allPageSuggestions
        accept(batch, toast: AcceptAllKind.appInformation.acceptedText(batch.count, groups: pageCount(of: batch), withoutAsking: true))
    }

    /// The sheet's Accept: only what was left ticked.
    func acceptSuggestions(ids: Set<String>, turnedOffAsking: Bool) {
        let batch = allPageSuggestions.filter { ids.contains($0.id) }
        accept(batch, toast: AcceptAllKind.appInformation.acceptedText(batch.count, groups: pageCount(of: batch), turnedOffAsking: turnedOffAsking))
    }

    private func pageCount(of batch: [FieldSuggestion]) -> Int {
        Set(batch.compactMap(\.target.scope.page)).count
    }
}
