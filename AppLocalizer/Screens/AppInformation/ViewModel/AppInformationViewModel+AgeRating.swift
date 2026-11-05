//
//  AppInformationViewModel+AgeRating.swift
//  AppLocalizer
//

import Foundation

// Age Rating: answers, assistants' answers with their evidence and
// Confirmed checkbox, and the override with its reason.
extension AppInformationViewModel {
    /// App Store Connect's answers with the queued ones on top.
    var ageRating: AgeRatingValues? {
        content.map { builder.ageRating($0.ageRating, with: changes) }
    }

    var ratingPreview: AgeRatingPreview? { ageRating?.preview }

    /// The rating changes with the next push.
    var ratingChanges: Bool {
        guard let content, let preview = ratingPreview else { return false }
        return preview.effective != content.ageRating.preview.effective
    }

    /// Questions an assistant answered, with who and whether you confirmed.
    /// An accepted suggestion isn't one: it shows who suggested it instead.
    var assistantAnswers: [AgeRatingQuestion: (client: String, confirmed: Bool)] {
        builder.assistantAnswers(in: changes).filter { question, _ in
            suggestions.provenance(for: AppInformationSuggestionSlot.ageRating(question).target, appID: app.id) == nil
        }
    }

    /// "Claude Code answered 7 questions from the project · 5 not confirmed
    /// yet" (or "· all confirmed"), with how many are left for Confirm All;
    /// nil when no assistant answered.
    var assistantBanner: (client: String, text: String, unconfirmed: Int)? {
        let answers = assistantAnswers
        guard let client = answers.values.first?.client else { return nil }
        let open = answers.values.count { !$0.confirmed }
        let answered = answers.count == 1
            ? String(localized: "answered 1 question from the project")
            : String(localized: "answered \(answers.count) questions from the project")
        let state = open == 0 ? String(localized: "all confirmed") : String(localized: "\(open) not confirmed yet")
        return (client, answered + " · " + state, open)
    }

    /// You picked an answer: it replaces an assistant's.
    func setAnswer(_ answer: AgeRatingAnswer, for question: AgeRatingQuestion) {
        guard let content, ageRating?.answers[question] != answer else { return }
        apply(builder.ageAnswerChange(question, from: content.ageRating, to: answer), id: builder.changeID(.ageRating, question.rawValue))
    }

    /// The Confirmed checkbox next to an assistant's answer.
    func confirmAnswer(_ question: AgeRatingQuestion, _ confirmed: Bool) {
        guard let content, let ageRating, let client = assistantAnswers[question]?.client else { return }
        let change = builder.ageAnswerChange(
            question,
            from: content.ageRating,
            to: ageRating.answers[question],
            source: .assistant(client: client),
            confirmed: confirmed
        )
        apply(change, id: builder.changeID(.ageRating, question.rawValue))
    }

    /// Confirm All in the banner: every assistant answer not confirmed yet
    /// is, as if its Confirmed box were checked. Answers stay as proposed.
    func confirmAllAnswers() {
        let open = assistantAnswers.filter { !$0.value.confirmed }.keys
        for question in AgeRatingQuestion.allCases where open.contains(question) {
            confirmAnswer(question, true)
        }
    }

    /// Reject in the evidence popover: the answer goes back to App Store
    /// Connect's.
    func rejectAnswer(_ question: AgeRatingQuestion) {
        queue.discard(id: builder.changeID(.ageRating, question.rawValue))
        notes.ageEvidence[question.rawValue] = nil
        evidenceQuestion = nil
    }

    func evidence(for question: AgeRatingQuestion) -> AssistantEvidence? {
        notes.ageEvidence[question.rawValue]
    }

    // MARK: - Override

    /// "Rate higher than calculated".
    var isOverrideOn: Bool { ageRating?.override != nil }

    /// Turns the override on at the next rating up, or off.
    func setOverrideOn(_ isOn: Bool) {
        guard let preview = ratingPreview else { return }
        setOverride(isOn ? AgeRating.overrides(above: preview.calculated).first ?? .eighteenPlus : nil)
    }

    func setOverride(_ rating: AgeRating?) {
        guard let content else { return }
        apply(
            builder.overrideChange(from: content.ageRating, to: rating, reason: notes.overrideReason),
            id: builder.changeID(.ageRating, AppInformationChangeBuilder.overrideKey)
        )
    }

    /// The reason is kept on this Mac (App Store Connect has no field for
    /// it) and shown with the override in review.
    func setOverrideReason(_ reason: String) {
        notes.overrideReason = reason
        if let override = ageRating?.override { setOverride(override) }
    }
}
