//
//  ScreenshotUploadItem.swift
//  AppLocalizer
//

import Foundation

/// One image in a running screenshot push: what it sends, how far it got,
/// and what App Store Connect gave back, so a retry resumes rather than
/// starting over.
struct ScreenshotUploadItem: Identifiable, Hashable, Sendable {
    var plan: ScreenshotPlanItem
    var groupID: String
    var localeName: String
    var status: ScreenshotUploadStatus = .queued
    /// The live screenshot it replaces, kept on this Mac before it's
    /// deleted.
    var backup: ScreenshotBackupImage?
    /// The `appScreenshots` ID once reserved.
    var screenshotID: String?
    /// The MD5 of the uploaded file.
    var checksum: String?
    /// Committed and accepted for processing: the old one can go.
    var isCommitted = false
    /// Apple finished processing it: only then does the old one go, so a
    /// file Apple fails can't leave the slot empty.
    var isDeliveryConfirmed = false
    var isOldDeleted = false
    /// Something worth knowing beside how the image went, e.g. the old
    /// screenshot couldn't be deleted, or had no image to keep.
    var note: String?

    var id: String { plan.id }

    var appID: StoreApp.ID { plan.appID }

    /// "Arabic · iPhone · 1 Today", or "… · restore".
    var title: String {
        let title = plan.title(localeName: localeName)
        return plan.isRestore ? String(localized: "\(title) · restore") : title
    }
}
