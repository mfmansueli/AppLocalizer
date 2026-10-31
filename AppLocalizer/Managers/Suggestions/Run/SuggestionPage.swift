//
//  SuggestionPage.swift
//  AppLocalizer
//

import Foundation

/// The five places suggestions show, as Overview counts them and Suggest
/// Everything lists them: the Store Page, then App Information's General,
/// Age Rating, Accessibility and App Review.
enum SuggestionPage: String, CaseIterable, Identifiable, Hashable, Sendable {
    case storePage
    case general
    case ageRating
    case accessibility
    case appReview

    var id: String { rawValue }

    init?(_ scope: SuggestionScope) {
        switch scope {
        case .storePage: self = .storePage
        case .accessibility: self = .accessibility
        case .appInformation:
            switch scope.page {
            case .general: self = .general
            case .ageRating: self = .ageRating
            case .appReview: self = .appReview
            default: return nil
            }
        }
    }

    var title: String {
        switch self {
        case .storePage: String(localized: "Store Page")
        case .general, .ageRating, .accessibility, .appReview: appInformationPage?.title ?? rawValue
        }
    }

    /// The App Information page it is; nil for the Store Page.
    var appInformationPage: AppInformationPage? {
        switch self {
        case .storePage: nil
        case .general: .general
        case .ageRating: .ageRating
        case .accessibility: .accessibility
        case .appReview: .appReview
        }
    }

    var area: SuggestionArea {
        self == .storePage ? .storePage : .appInformation
    }

    /// A target's name in a run's rows: "Subtitle", "Secondary Category",
    /// "Health or Wellness Topics", "VoiceOver".
    static func fieldTitle(of target: SuggestionTarget) -> String {
        switch target.scope {
        case .storePage: ListingField(rawValue: target.field)?.title ?? target.field
        case .appInformation, .accessibility: AppInformationSuggestionSlot(target: target)?.title ?? target.field
        }
    }
}
