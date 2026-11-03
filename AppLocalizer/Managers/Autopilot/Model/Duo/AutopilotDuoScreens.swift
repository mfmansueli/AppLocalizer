//
//  AutopilotDuoScreens.swift
//  AppLocalizer
//

import Foundation

/// The plan's iPhone Duo row: what its screenshots show. Every image is
/// at Apple's 2007 × 2853, so a cover display is framed inside it.
enum AutopilotDuoScreens: String, Codable, CaseIterable, Hashable, Sendable {
    /// Unfolded, the app on the inner display: AppLocalizer opens the Duo
    /// in Device Hub for each capture.
    case inner
    /// Folded, the app on the cover display. Faster, since the Duo never
    /// opens, but the big screen isn't shown.
    case cover
    /// Both displays, side by side in one image or as separate
    /// screenshots (`AutopilotDuoBoth`).
    case both

    var title: String {
        switch self {
        case .inner: String(localized: "Inner display")
        case .cover: String(localized: "Cover display")
        case .both: String(localized: "Both")
        }
    }
}
