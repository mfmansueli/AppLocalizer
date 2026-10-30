//
//  SuggestionScope.swift
//  AppLocalizer
//

import Foundation

/// Where a suggestion is shown: one Store Page language, one App
/// Information page, or Accessibility on one device. The suggestion bar
/// works on one scope at a time.
enum SuggestionScope: Hashable, Codable, Sendable {
    /// A Store Page language, by App Store Connect locale code, e.g. `de-DE`.
    case storePage(locale: String)
    /// An App Information page, by `AppInformationPage` raw value:
    /// `general`, `ageRating` or `appReview`.
    case appInformation(page: String)
    /// Accessibility on one device, by `DeviceFamily` raw value, e.g.
    /// `APPLE_WATCH`.
    case accessibility(family: String)

    var area: SuggestionArea {
        switch self {
        case .storePage: .storePage
        case .appInformation, .accessibility: .appInformation
        }
    }

    /// `store.de-DE` or `info.general`, for ids and MCP results.
    var id: String {
        switch self {
        case let .storePage(locale): "store.\(locale)"
        case let .appInformation(page): "info.\(page)"
        case let .accessibility(family): "info.accessibility.\(family)"
        }
    }

    /// "German" or "App Review", as the bar and toasts name it.
    var title: String {
        switch self {
        case let .storePage(code): StoreLocaleCatalog.locale(code: code)?.name ?? code
        case let .appInformation(page): AppInformationPage(rawValue: page)?.title ?? page
        case let .accessibility(family):
            "\(AppInformationPage.accessibility.title) · \(DeviceFamily(rawValue: family)?.name ?? family)"
        }
    }

    static func appInformation(_ page: AppInformationPage) -> SuggestionScope {
        .appInformation(page: page.rawValue)
    }

    static func accessibility(_ family: DeviceFamily) -> SuggestionScope {
        .accessibility(family: family.rawValue)
    }

    /// The App Information page it's on; nil for the Store Page.
    var page: AppInformationPage? {
        switch self {
        case .storePage: nil
        case let .appInformation(page): AppInformationPage(rawValue: page)
        case .accessibility: .accessibility
        }
    }

    static func storePage(_ locale: StoreLocale) -> SuggestionScope {
        .storePage(locale: locale.code)
    }
}
