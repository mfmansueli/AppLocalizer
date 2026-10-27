//
//  PushEstimate.swift
//  AppLocalizer
//

import Foundation

/// The review footer's "~340 requests · about 6 min": every write plus
/// each conflict check, sent one at a time at roughly one a second.
struct PushEstimate: Hashable, Sendable {
    var requestCount: Int

    init(changes: some Sequence<PendingChange>) {
        requestCount = changes.reduce(0) { $0 + $1.estimatedRequestCount }
    }

    var minutes: Int {
        max(1, Int((Double(requestCount) / 60).rounded(.up)))
    }

    var text: String {
        String(localized: "~\(requestCount) requests · about \(minutes) min")
    }
}
