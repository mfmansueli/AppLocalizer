//
//  AppScreenshotSetPage.swift
//  AppLocalizer
//

import Foundation

/// `GET /v1/appStoreVersionLocalizations/{id}/appScreenshotSets?include=appScreenshots`:
/// each set's display type and the screenshots it links to. Only the
/// linkage is read, since the Screenshots view just counts them.
struct AppScreenshotSetPage: Decodable, Sendable {
    var data: [ScreenshotSet]
    var links: AppStoreConnectPageLinks?

    struct ScreenshotSet: Decodable, Sendable {
        var id: String
        var attributes: Attributes
        var relationships: Relationships?

        /// How many screenshots the set links to.
        var screenshotCount: Int { relationships?.appScreenshots?.data?.count ?? 0 }
    }

    struct Attributes: Decodable, Sendable {
        /// E.g. `APP_IPHONE_67`, `APP_IPAD_PRO_3GEN_129` or `APP_DESKTOP`.
        var screenshotDisplayType: String
    }

    struct Relationships: Decodable, Sendable {
        var appScreenshots: Linkage?
    }

    struct Linkage: Decodable, Sendable {
        var data: [Identifier]?
    }

    struct Identifier: Decodable, Sendable {
        var type: String
        var id: String
    }
}
