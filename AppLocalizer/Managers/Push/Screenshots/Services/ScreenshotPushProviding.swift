//
//  ScreenshotPushProviding.swift
//  AppLocalizer
//

import Foundation

/// Screenshots services that can also push. Review & Push lists
/// screenshots only for services that do; DEBUG scenes without it show
/// text changes alone.
@MainActor
protocol ScreenshotPushProviding {
    var pushing: any ScreenshotPushServices { get }
}
