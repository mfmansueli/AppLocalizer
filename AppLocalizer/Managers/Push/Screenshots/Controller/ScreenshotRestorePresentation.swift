//
//  ScreenshotRestorePresentation.swift
//  AppLocalizer
//

import Foundation

/// Restore Previous Screenshots… open for one push, optionally on a locale.
struct ScreenshotRestorePresentation: Identifiable, Hashable, Sendable {
    var recordID: PushRecord.ID
    var locale: String?

    var id: PushRecord.ID { recordID }
}
