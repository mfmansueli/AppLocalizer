//
//  SectionLoadStamp.swift
//  AppLocalizer
//

import Foundation

/// When a section last finished reading App Store Connect: the Refresh
/// count it read under, and the time.
struct SectionLoadStamp: Equatable, Sendable {
    var refreshCount: Int
    var date: Date

    /// Still good to show without reading again: no Refresh (⌘R, or a
    /// push) happened since, and it isn't older than `maximumAge`.
    func isFresh(refreshCount: Int, now: Date, maximumAge: TimeInterval) -> Bool {
        self.refreshCount == refreshCount && now.timeIntervalSince(date) < maximumAge
    }
}
