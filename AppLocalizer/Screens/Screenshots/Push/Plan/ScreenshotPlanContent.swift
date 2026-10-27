//
//  ScreenshotPlanContent.swift
//  AppLocalizer
//

import Foundation

/// What one planned image uploads: a render made from the template, or a
/// screenshot kept on this Mac by an earlier push that goes back.
enum ScreenshotPlanContent: Hashable, Sendable {
    case render(RenderJob)
    case restore(ScreenshotBackupImage)

    var renderJob: RenderJob? {
        if case let .render(job) = self { return job }
        return nil
    }

    var backupImage: ScreenshotBackupImage? {
        if case let .restore(image) = self { return image }
        return nil
    }
}
