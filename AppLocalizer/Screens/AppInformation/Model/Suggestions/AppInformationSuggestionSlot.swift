//
//  AppInformationSuggestionSlot.swift
//  AppLocalizer
//

import Foundation

/// What an App Information suggestion is for: a General or App Review
/// field, an Age Rating question, or an Accessibility feature on one
/// device. Questions and features take answers rather than text, so their
/// cards show the answers and have no Use and Edit. Answers are stored as
/// `AgeRatingAnswer` raw values, and as `yes` or `no` for a feature.
enum AppInformationSuggestionSlot: Hashable, Sendable {
    case field(AppInformationSuggestionField)
    case ageRating(AgeRatingQuestion)
    case accessibility(DeviceFamily, AccessibilityFeature)

    /// A feature's stored answers.
    static let supported = "yes"
    static let unsupported = "no"

    init?(target: SuggestionTarget) {
        switch target.scope {
        case .storePage:
            return nil
        case .appInformation(page: AppInformationPage.ageRating.rawValue):
            guard let question = AgeRatingQuestion(rawValue: target.field) else { return nil }
            self = .ageRating(question)
        case .appInformation:
            guard let field = AppInformationSuggestionField(rawValue: target.field), target.scope == .appInformation(field.page) else {
                return nil
            }
            self = .field(field)
        case let .accessibility(code):
            guard let family = DeviceFamily(rawValue: code), let feature = AccessibilityFeature(rawValue: target.field),
                  feature.isAvailable(on: family)
            else { return nil }
            self = .accessibility(family, feature)
        }
    }

    var target: SuggestionTarget {
        switch self {
        case let .field(field): .appInformation(field)
        case let .ageRating(question): SuggestionTarget(.appInformation(.ageRating), field: question.rawValue)
        case let .accessibility(family, feature): SuggestionTarget(.accessibility(family), field: feature.rawValue)
        }
    }

    var scope: SuggestionScope { target.scope }

    /// "Copyright", "Health or wellness topics", "VoiceOver".
    var title: String {
        switch self {
        case let .field(field): field.title
        case let .ageRating(question): question.title
        case let .accessibility(_, feature): feature.name
        }
    }

    /// Answered from a list of choices rather than typed.
    var isChoice: Bool {
        if case .field = self { return false }
        return true
    }

    /// What can't be edited after it goes in: choices and picked fields.
    var canUseAndEdit: Bool {
        guard case let .field(field) = self else { return false }
        return !field.isPicked
    }

    /// The stored answers a question or feature takes, in the picker's
    /// order; empty for a field.
    var choices: [String] {
        switch self {
        case .field: []
        case let .ageRating(question): question.answers.map(\.rawValue)
        case .accessibility: [Self.supported, Self.unsupported]
        }
    }

    /// What the person reads: a category by name, an answer as "Yes" or
    /// "Infrequent". An unanswered question or feature reads "Not
    /// answered".
    func displayValue(_ value: String) -> String {
        switch self {
        case let .field(field):
            return field.displayValue(value)
        case .ageRating:
            guard !value.isEmpty else { return String(localized: "Not answered") }
            return AgeRatingAnswer(rawValue: value)?.title ?? value
        case .accessibility:
            switch value {
            case Self.supported: return String(localized: "Yes")
            case Self.unsupported: return String(localized: "No")
            default: return String(localized: "Not answered")
            }
        }
    }

    /// An assistant's value as it's stored: an answer by name ("Yes",
    /// "Infrequent"), raw value or, for Yes/No, a boolean, ignoring case;
    /// nil when it isn't one of the answers.
    func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch self {
        case let .field(field):
            return field.normalized(value)
        case let .ageRating(question):
            let booleans = question.hasLevels ? [:] : ["true": AgeRatingAnswer.affirmative, "false": .negative]
            let answer = question.answers.first { [$0.rawValue.lowercased(), $0.title.lowercased()].contains(trimmed) } ?? booleans[trimmed]
            return answer?.rawValue
        case .accessibility:
            let answers = ["yes": Self.supported, "true": Self.supported, "no": Self.unsupported, "false": Self.unsupported]
            return answers[trimmed]
        }
    }

    /// "Yes, No" or "None, Infrequent, Frequent", for invalid_answer.
    var choiceList: String {
        choices.map(displayValue).joined(separator: ", ")
    }
}
