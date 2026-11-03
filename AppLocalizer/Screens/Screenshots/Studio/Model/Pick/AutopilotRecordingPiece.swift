//
//  AutopilotRecordingPiece.swift
//  AppLocalizer
//

import Foundation

/// A stretch of the raw recording on Pick's bar: between screens, a
/// moment (blue when it's in the App Preview), or the end of the take.
struct AutopilotRecordingPiece: Hashable, Identifiable {
    enum Kind: Hashable {
        case between
        case moment(chosen: Bool)
        case end
    }

    var id: String
    var start: Double
    var end: Double
    var kind: Kind
    /// "Between screens", "Today · 0:02–0:08 · in the App Preview".
    var title: String

    var length: Double { max(end - start, 0) }
}
