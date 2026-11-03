//
//  AutopilotRecordingUpload.swift
//  AppLocalizer
//

import Foundation

/// A Simulator recording the assistant sent to the upload link, waiting
/// for its `report_recording`.
struct AutopilotRecordingUpload: Hashable, Sendable {
    var id: String
    var appID: StoreApp.ID
    var runID: String
    var file: RecordingFile
    var receivedAt: Date
}
