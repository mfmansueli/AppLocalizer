//
//  ScreenshotCaptionsRequest.swift
//  AppLocalizer
//

import Foundation

/// Review & Push's Show in Captions: the Screenshots view opens Captions on
/// this render once it's showing the app.
struct ScreenshotCaptionsRequest: Hashable, Sendable {
    var appID: StoreApp.ID
    var cell: ScreenshotCellKey
}
