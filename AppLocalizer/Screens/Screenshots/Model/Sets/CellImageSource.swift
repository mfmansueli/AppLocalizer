//
//  CellImageSource.swift
//  AppLocalizer
//

import Foundation

/// What a cell shows: a render from the template, or the screenshot that's
/// live in App Store Connect (uploaded by hand, or restored and pinned).
enum CellImageSource: Hashable, Sendable {
    case render(RenderJob)
    case live(LiveScreenshot)
    case none

    var renderJob: RenderJob? {
        if case let .render(job) = self { return job }
        return nil
    }
}
