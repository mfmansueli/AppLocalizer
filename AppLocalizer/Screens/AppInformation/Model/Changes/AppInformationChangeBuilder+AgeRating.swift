//
//  AppInformationChangeBuilder+AgeRating.swift
//  AppLocalizer
//

import Foundation

// Age Rating: one change per answered question and one for the override,
// each a `PATCH` of the app info's age rating declaration.
extension AppInformationChangeBuilder {
    static let overrideKey = "override"
    static let overrideAttribute = "ageRatingOverrideV2"

    /// One question's answer; nil when it's back at App Store Connect's.
    /// An assistant's answer waits for Confirmed before it can be pushed.
    func ageAnswerChange(
        _ question: AgeRatingQuestion,
        from values: AgeRatingValues,
        to answer: AgeRatingAnswer,
        source: ChangeSource = .you,
        confirmed: Bool = true
    ) -> PendingChange? {
        let old = values.answers[question]
        guard old != answer || !values.isAnswered(question), let declarationID = ids.ageRatingDeclarationID else { return nil }
        let unconfirmed = source.isAssistant && !confirmed
        return PendingChange(
            id: changeID(.ageRating, question.rawValue),
            appID: appID,
            section: .appInformation,
            group: group(.ageRating),
            title: question.title,
            oldValue: values.isAnswered(question) ? old.title : String(localized: "Not answered"),
            newValue: answer.title,
            source: source,
            blockedReason: unconfirmed ? String(localized: "Confirm \(source.title)’s answer on the Age Rating page first.") : nil,
            requests: [Self.patch("ageRatingDeclarations", id: declarationID, attributes: [question.apiKey: answer.apiValue])],
            restoreRequests: values.apiValues[question.apiKey].map {
                [Self.patch("ageRatingDeclarations", id: declarationID, attributes: [question.apiKey: $0])]
            } ?? [],
            conflictCheck: ageCheck(question.apiKey, expected: values.apiValues[question.apiKey]?.conflictValue)
        )
    }

    /// "Rate higher than calculated", with the reason in the new value.
    func overrideChange(from values: AgeRatingValues, to override: AgeRating?, reason: String) -> PendingChange? {
        guard values.override != override, let declarationID = ids.ageRatingDeclarationID else { return nil }
        let off = String(localized: "Off")
        let newValue = override.map { reason.isEmpty ? $0.title : "\($0.title) · \(reason)" } ?? off
        return PendingChange(
            id: changeID(.ageRating, Self.overrideKey),
            appID: appID,
            section: .appInformation,
            group: group(.ageRating),
            title: String(localized: "Rate higher than calculated"),
            oldValue: values.override?.title ?? off,
            newValue: newValue,
            blockedReason: override != nil && reason.trimmingCharacters(in: .whitespaces).isEmpty
                ? String(localized: "Say why the app should be rated higher.") : nil,
            requests: [Self.patch("ageRatingDeclarations", id: declarationID, attributes: [Self.overrideAttribute: .string(override?.apiValue ?? "NONE")])],
            restoreRequests: [Self.patch("ageRatingDeclarations", id: declarationID, attributes: [
                Self.overrideAttribute: .string(values.override?.apiValue ?? "NONE"),
            ])],
            conflictCheck: ageCheck(Self.overrideAttribute, expected: values.apiValues[Self.overrideAttribute]?.conflictValue)
        )
    }

    private func ageCheck(_ key: String, expected: String?) -> ConflictCheck {
        Self.attributeCheck("/v1/appInfos/\(ids.appInfoID)/ageRatingDeclaration", key: key, expected: expected)
    }

    // MARK: - Reading

    /// App Store Connect's answers with the queued ones on top.
    func ageRating(_ values: AgeRatingValues, with changes: [PendingChange]) -> AgeRatingValues {
        var values = values
        for change in changes where owns(change) && page(of: change) == .ageRating {
            guard let attributes = Self.document(of: change)?.data.attributes else { continue }
            for (key, value) in attributes {
                if key == Self.overrideAttribute {
                    values.override = value.stringValue.flatMap { AgeRating(apiValue: $0) }
                } else if let question = AgeRatingQuestion.question(apiKey: key), let answer = AgeRatingAnswer(apiValue: value) {
                    values.answers[question] = answer
                }
            }
        }
        return values
    }

    /// The queued assistant answers, by question: who proposed each, and
    /// whether it's confirmed (no longer blocked).
    func assistantAnswers(in changes: [PendingChange]) -> [AgeRatingQuestion: (client: String, confirmed: Bool)] {
        var answers: [AgeRatingQuestion: (client: String, confirmed: Bool)] = [:]
        for change in changes where owns(change) && page(of: change) == .ageRating {
            guard case let .assistant(client) = change.source,
                  let question = AgeRatingQuestion(rawValue: String(change.id.dropFirst(changeID(.ageRating, "").count)))
            else { continue }
            answers[question] = (client, change.blockedReason == nil)
        }
        return answers
    }
}
