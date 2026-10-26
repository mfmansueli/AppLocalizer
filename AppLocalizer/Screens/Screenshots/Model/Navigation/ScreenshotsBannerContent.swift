//
//  ScreenshotsBannerContent.swift
//  AppLocalizer
//

import Foundation

/// The banner over the Sets matrix: no version to push to (a warning), or
/// renders failing their checks (an error naming the first one).
enum ScreenshotsBannerContent: Hashable, Sendable {
    case noVersion(title: String, message: String)
    case failedChecks(title: String, message: String, first: ScreenshotCellKey)
}
