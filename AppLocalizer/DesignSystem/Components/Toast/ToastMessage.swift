//
//  ToastMessage.swift
//  AppLocalizer
//

import Foundation

/// What an action did, for an `ActionToast`: "Accepted 5 suggestions in
/// German. Nothing is pushed yet." and whether Undo can take it back. A new
/// id per message, so the same text twice shows (and is announced) twice.
struct ToastMessage: Identifiable, Hashable, Sendable {
    var id = UUID()
    var text: String
    /// Shows Undo, which the section handles.
    var canUndo = false
}
