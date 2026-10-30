//
//  AppInformationSuggestionField.swift
//  AppLocalizer
//

import Foundation

/// The App Information fields that take suggestions, on General and App
/// Review. Raw values are the names MCP uses (`suggest_fields`). A picked
/// value is kept as App Store Connect's id (`PRODUCTIVITY`,
/// `AFTER_APPROVAL`) and shown by name.
enum AppInformationSuggestionField: String, CaseIterable, Identifiable, Hashable, Sendable {
    case copyright
    case primaryCategory
    case secondaryCategory
    case release
    case contactFirstName
    case contactLastName
    case contactPhone
    case contactEmail
    case notes

    var id: String { rawValue }

    var page: AppInformationPage {
        switch self {
        case .copyright, .primaryCategory, .secondaryCategory, .release: .general
        case .contactFirstName, .contactLastName, .contactPhone, .contactEmail, .notes: .appReview
        }
    }

    var title: String {
        switch self {
        case .copyright: String(localized: "Copyright")
        case .primaryCategory: String(localized: "Primary Category")
        case .secondaryCategory: String(localized: "Secondary Category")
        case .release: String(localized: "Version Release")
        case .contactFirstName, .contactLastName, .contactPhone, .contactEmail, .notes: reviewField?.title ?? rawValue
        }
    }

    /// The App Review field it is, on that page.
    var reviewField: AppReviewField? {
        switch self {
        case .contactFirstName: .firstName
        case .contactLastName: .lastName
        case .contactPhone: .phone
        case .contactEmail: .email
        case .notes: .notes
        case .copyright, .primaryCategory, .secondaryCategory, .release: nil
        }
    }

    /// Set per version (copyright, release, App Review), so a version in
    /// review or live is locked; the categories belong to the app.
    var isVersionLevel: Bool {
        self != .primaryCategory && self != .secondaryCategory
    }

    /// Picked from a list rather than typed.
    var isPicked: Bool {
        self == .primaryCategory || self == .secondaryCategory || self == .release
    }

    var limit: Int? {
        self == .notes ? AppReviewField.notesLimit : nil
    }

    var isMultiline: Bool { self == .notes }

    /// The suggestion field an App Review field is, if it takes them.
    init?(reviewField: AppReviewField) {
        guard let field = Self.allCases.first(where: { $0.reviewField == reviewField }) else { return nil }
        self = field
    }

    static func fields(on page: AppInformationPage) -> [AppInformationSuggestionField] {
        allCases.filter { $0.page == page }
    }

    /// The pages that take suggestions.
    static let pages: [AppInformationPage] = [.general, .appReview]

    /// What the person reads for a stored value: a category's or release
    /// option's name, the text otherwise.
    func displayValue(_ value: String) -> String {
        switch self {
        case .primaryCategory, .secondaryCategory: AppCategory.name(for: value.isEmpty ? nil : value)
        case .release: ReleaseOption(rawValue: value)?.title ?? value
        default: value
        }
    }

    /// An assistant's value as it's stored: a category or release option
    /// by id or name, ignoring case; nil when it's none of them.
    func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        switch self {
        case .primaryCategory, .secondaryCategory:
            let match = AppCategory.all.first { [$0.id, $0.name].contains { $0.caseInsensitiveCompare(trimmed) == .orderedSame } }
            return match?.id
        case .release:
            let match = ReleaseOption.allCases.first { [$0.rawValue, $0.title].contains { $0.caseInsensitiveCompare(trimmed) == .orderedSame } }
            return match?.rawValue
        case .notes:
            return value
        default:
            return trimmed
        }
    }

    /// The field's value in the page's values, as stored.
    func value(general: GeneralValues?, review: AppReviewValues?) -> String {
        switch self {
        case .copyright: general?.copyright ?? ""
        case .primaryCategory: general?.primaryCategory ?? ""
        case .secondaryCategory: general?.secondaryCategory ?? ""
        case .release: general?.release?.rawValue ?? ""
        case .contactFirstName, .contactLastName, .contactPhone, .contactEmail, .notes: reviewField.map { review?.text($0) ?? "" } ?? ""
        }
    }
}
