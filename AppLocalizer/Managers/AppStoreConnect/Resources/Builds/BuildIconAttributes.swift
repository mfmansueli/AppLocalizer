//
//  BuildIconAttributes.swift
//  AppLocalizer
//

import Foundation

/// An icon App Store Connect extracted from a build's binary
/// (`buildIcons`). Its type says which part of the build it belongs to.
struct BuildIconAttributes: Decodable, Sendable {
    /// The watch app's App Store icon: the build has an Apple Watch app.
    static let watchAppStore = "WATCH_APP_STORE"

    /// `APP_STORE`, `MESSAGES_APP_STORE`, `WATCH_APP_STORE`,
    /// `TV_OS_HOME_SCREEN`, `TV_OS_TOP_SHELF` or `ALTERNATE_EXPERIMENT`.
    var iconType: String?
}
