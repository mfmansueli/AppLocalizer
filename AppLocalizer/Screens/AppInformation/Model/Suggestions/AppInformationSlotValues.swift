//
//  AppInformationSlotValues.swift
//  AppLocalizer
//

import Foundation

/// App Information's suggestion slots as shown: App Store Connect's values
/// with everything queued laid on top, whether each can take a value, and
/// the change that gives one a new value. The page and `suggest_fields`
/// both go through it, so an assistant's answer lands where the person's
/// would.
struct AppInformationSlotValues {
    let content: AppInformationContent
    /// Nil until Accessibility has loaded.
    let accessibility: AccessibilityContent?
    let builder: AppInformationChangeBuilder
    let changes: [PendingChange]

    var general: GeneralValues {
        builder.general(content.general, with: changes)
    }

    /// App Review's password isn't a suggestion field, so the Keychain
    /// isn't read for it.
    var review: AppReviewValues {
        builder.review(content.review, with: changes) { nil }
    }

    var accessibilityCards: [AccessibilityCard] {
        accessibility.map { builder.accessibilityCards($0, with: changes) } ?? []
    }

    /// Families the app may run on that App Store Connect doesn't list:
    /// Apple Watch for an iOS app, since an iOS version doesn't say whether
    /// it ships a watch app.
    var otherFamilies: [DeviceFamily] {
        let shown = Set(accessibilityCards.map(\.family))
        guard shown.contains(.iPhone), !shown.contains(.appleWatch) else { return [] }
        return [.appleWatch]
    }

    /// Every family a feature can be suggested for: the cards' and Other
    /// Devices'.
    var accessibilityFamilies: [DeviceFamily] {
        accessibilityCards.map(\.family) + otherFamilies
    }

    /// The family's card; for one from Other Devices, a card with no
    /// declaration.
    func card(for family: DeviceFamily) -> AccessibilityCard? {
        if let card = accessibilityCards.first(where: { $0.family == family }) { return card }
        guard let accessibility, otherFamilies.contains(family) else { return nil }
        return AccessibilityCard(family: family, isLive: accessibility.liveFamilies.contains(family), upcomingVersion: accessibility.upcomingVersion)
    }

    /// Its value as shown, as stored: a category by id, an answer by raw
    /// value, a feature as `yes` or `no`; "" when a question or feature
    /// hasn't been answered.
    func value(_ slot: AppInformationSuggestionSlot) -> String {
        switch slot {
        case let .field(field):
            return field.value(general: general, review: review)
        case let .ageRating(question):
            let isQueued = Self.change(builder.changeID(.ageRating, question.rawValue), in: changes) != nil
            guard content.ageRating.isAnswered(question) || isQueued else { return "" }
            return builder.ageRating(content.ageRating, with: changes).answers[question].rawValue
        case let .accessibility(family, feature):
            guard let shown = card(for: family)?.shown else { return "" }
            return shown.features.contains(feature) ? AppInformationSuggestionSlot.supported : AppInformationSuggestionSlot.unsupported
        }
    }

    /// App Store Connect's value, before anything queued.
    func liveValue(_ slot: AppInformationSuggestionSlot) -> String {
        AppInformationSlotValues(content: content, accessibility: accessibility, builder: builder, changes: []).value(slot)
    }

    /// Whether it can take a value: the categories always, the version's
    /// fields while it's editable, the questionnaire once App Store Connect
    /// returned it, a feature once Accessibility loaded, on the app's
    /// devices.
    func canSuggest(_ slot: AppInformationSuggestionSlot) -> Bool {
        switch slot {
        case let .field(field): !field.isVersionLevel || content.isVersionEditable
        case .ageRating: content.ids.ageRatingDeclarationID != nil
        case let .accessibility(family, _): card(for: family) != nil
        }
    }

    /// Its value differs from App Store Connect's: a queued change.
    func isPending(_ slot: AppInformationSuggestionSlot) -> Bool {
        switch slot {
        case let .field(field):
            return value(slot) != field.value(general: content.general, review: content.review)
        case let .ageRating(question):
            return Self.change(builder.changeID(.ageRating, question.rawValue), in: changes) != nil
        case let .accessibility(family, feature):
            guard let card = card(for: family), let queued = card.queued else { return false }
            guard let base = card.draft ?? card.published else { return true }
            return queued.features.contains(feature) != base.features.contains(feature)
        }
    }

    /// The change that gives it `value`, tagged with `source`, and the id
    /// it's queued under; the change is nil when nothing needs queuing
    /// there (it's App Store Connect's value). "" takes a question or
    /// feature back to unanswered. An unconfirmed answer waits for
    /// Confirmed on Age Rating. Nil when it can't take the value.
    func change(
        _ slot: AppInformationSuggestionSlot,
        to value: String,
        source: ChangeSource,
        confirmed: Bool = true
    ) -> (change: PendingChange?, id: PendingChange.ID)? {
        guard canSuggest(slot) else { return nil }
        switch slot {
        case let .field(field):
            let values = AppInformationSuggestionWriter.Values(content: content, general: general, review: review, builder: builder)
            return AppInformationSuggestionWriter.change(field, to: value, in: values, source: source)
        case let .ageRating(question):
            let id = builder.changeID(.ageRating, question.rawValue)
            guard let answer = AgeRatingAnswer(rawValue: value) else { return value.isEmpty ? (nil, id) : nil }
            return (builder.ageAnswerChange(question, from: content.ageRating, to: answer, source: source, confirmed: confirmed), id)
        case let .accessibility(family, feature):
            guard var card = card(for: family), Self.featureValues.contains(value) else { return nil }
            let id = builder.accessibilityChangeID(family)
            var features = card.shown?.features ?? []
            if value == AppInformationSuggestionSlot.supported { features.insert(feature) } else { features.remove(feature) }
            if value.isEmpty, features == (card.draft ?? card.published)?.features ?? [] { return (nil, id) }
            card.queued = nil
            card.isDeletionQueued = false
            return (builder.declarationChange(for: card, answer: AccessibilityAnswer(features: features), source: source), id)
        }
    }

    /// A feature's answers, and "" for unanswered.
    private static let featureValues: Set = [AppInformationSuggestionSlot.supported, AppInformationSuggestionSlot.unsupported, ""]

    private static func change(_ id: PendingChange.ID, in changes: [PendingChange]) -> PendingChange? {
        changes.first { $0.id == id }
    }
}
