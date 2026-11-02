//
//  CaptureViewerTarget.swift
//  AppLocalizer
//

import Foundation

/// The capture the Captures tab's viewer shows: one locale's slot, on the
/// display type the tab is on.
struct CaptureViewerTarget: Hashable {
    var localeCode: String
    var slot: Int
}
