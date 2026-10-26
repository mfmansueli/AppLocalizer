//
//  AppPrivacyViewModel+Worksheet.swift
//  AppLocalizer
//

import Foundation

// The worksheet tab: answering, reviewing suggestions, open questions,
// conflicts and the cross-check. Every edit goes straight to the store.
extension AppPrivacyViewModel {
    /// A type's answer: the row's, or not collected.
    func answer(of type: PrivacyDataType) -> PrivacyAnswer {
        worksheet[type]?.answer ?? .notCollected
    }

    // MARK: - Starting

    /// "Start from scratch".
    func startFromScratch() {
        update { $0.start() }
    }

    /// "Enter what's in App Store Connect": every type, to copy today's
    /// answers in by hand.
    func enterFromAppStoreConnect() {
        update { $0.start() }
        filter = .all
        showsAllTypes = true
    }

    // MARK: - Answering

    func setCollects(_ value: Bool) {
        update { $0.setCollects(value) }
    }

    /// Collected or not. Collecting starts with the assistant's purposes,
    /// or App Functionality.
    func setCollected(_ type: PrivacyDataType, _ isCollected: Bool) {
        let suggested = worksheet[type]?.suggestion?.answer.purposes ?? []
        let answer = answer(of: type).settingCollected(isCollected, purposes: suggested.isEmpty ? [.appFunctionality] : suggested)
        update { $0.edit(type, to: answer) }
    }

    func togglePurpose(_ purpose: PrivacyPurpose, for type: PrivacyDataType) {
        let answer = answer(of: type).togglingPurpose(purpose)
        update { $0.edit(type, to: answer) }
    }

    func setLinked(_ type: PrivacyDataType, _ isLinked: Bool) {
        let answer = answer(of: type).settingLinked(isLinked)
        update { $0.edit(type, to: answer) }
    }

    func setTracking(_ type: PrivacyDataType, _ isTracking: Bool) {
        let answer = answer(of: type).settingTracking(isTracking)
        update { $0.edit(type, to: answer) }
    }

    // MARK: - Reviewing

    func accept(_ type: PrivacyDataType) {
        update { $0.accept(type) }
        if evidenceType == type { evidenceType = nil }
    }

    func reject(_ type: PrivacyDataType) {
        update { $0.reject(type) }
        if evidenceType == type { evidenceType = nil }
    }

    func acceptCollects() {
        update { $0.acceptCollects() }
    }

    /// How many suggestions Accept All High-Confidence would accept.
    var highConfidenceCount: Int {
        worksheet.highConfidenceTypes.count
    }

    func acceptAllHighConfidence() {
        var accepted = 0
        update { accepted = $0.acceptAllHighConfidence() }
        say(String(localized: "Accepted \(accepted) high-confidence suggestions. Conflicts and types with an open question were left for you."))
    }

    func keepYours(_ type: PrivacyDataType) {
        update { $0.keepYours(type) }
    }

    func useAssistants(_ type: PrivacyDataType) {
        update { $0.useAssistants(type) }
    }

    func answerQuestion(_ id: String, with answer: Bool) {
        update { $0.answerQuestion(id, with: answer) }
    }

    // MARK: - Cross-check

    func markCollected(_ type: PrivacyDataType) {
        update { $0.markCollected(type) }
    }

    func explainNotCollected(_ type: PrivacyDataType, because reason: String) {
        update { $0.explainNotCollected(type, because: reason) }
        explainingType = nil
    }

    // MARK: - What the tab shows

    /// The categories with at least one row under the filter, and their
    /// rows, in App Store Connect's order.
    var visibleCategories: [(category: PrivacyDataCategory, types: [PrivacyDataType])] {
        let worksheet = worksheet
        return PrivacyDataCategory.allCases.compactMap { category in
            let types = category.types.filter { worksheet.shows($0, under: filter, showingAll: showsAllTypes) }
            return types.isEmpty ? nil : (category, types)
        }
    }

    /// "2 collected" or "None collected": reviewed answers only.
    func collectedSummary(for category: PrivacyDataCategory) -> String {
        let answers = worksheet.reviewedAnswers
        let count = category.types.count { answers.collected[$0] != nil }
        return count == 0 ? String(localized: "None collected") : String(localized: "\(count) collected")
    }

    /// Types of the category the filter hides: "3 more not collected".
    func hiddenCount(in category: PrivacyDataCategory) -> Int {
        guard filter == .all, !showsAllTypes else { return 0 }
        let worksheet = worksheet
        return category.types.count { !worksheet.shows($0, under: .all, showingAll: false) }
    }

    /// The filter's title with its count, e.g. "Unreviewed · 9".
    func title(of filter: PrivacyWorksheetFilter) -> String {
        let worksheet = worksheet
        let count: Int? = switch filter {
        case .all: nil
        case .unreviewed: worksheet.unreviewedCount
        case .lowConfidence: worksheet.lowConfidenceCount
        case .openQuestions: worksheet.openQuestions.count
        }
        guard let count else { return filter.title }
        return "\(filter.title) · \(count)"
    }
}
