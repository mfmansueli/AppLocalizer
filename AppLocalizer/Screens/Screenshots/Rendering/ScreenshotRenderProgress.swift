//
//  ScreenshotRenderProgress.swift
//  AppLocalizer
//

import Foundation

/// How far the render queue is: "Rendering 22 of 60".
struct ScreenshotRenderProgress: Hashable, Sendable {
    var done: Int
    var total: Int

    var fraction: Double { total > 0 ? Double(done) / Double(total) : 0 }

    var title: String {
        String(localized: "Rendering \(done) of \(total)")
    }
}
