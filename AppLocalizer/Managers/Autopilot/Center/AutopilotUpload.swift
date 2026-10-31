//
//  AutopilotUpload.swift
//  AppLocalizer
//

import Foundation

/// A PNG the assistant sent to the upload link, waiting for its
/// `report_capture`.
struct AutopilotUpload: Hashable, Sendable {
    var id: String
    var appID: StoreApp.ID
    var runID: String
    var file: CaptureFile
    var receivedAt: Date
}
