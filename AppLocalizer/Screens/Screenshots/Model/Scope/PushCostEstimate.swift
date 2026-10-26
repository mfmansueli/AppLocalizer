//
//  PushCostEstimate.swift
//  AppLocalizer
//

import Foundation

/// What pushing images costs in App Store Connect requests: about four per
/// image (reserve, upload, commit, then a status read), one per live
/// screenshot it replaces (delete) and one per set (reorder), against the
/// 3,600 requests an hour Apple allows.
struct PushCostEstimate: Hashable, Sendable {
    static let hourlyLimit = 3600
    static let requestsPerImage = 4
    /// Roughly how long a request takes, for the minutes estimate.
    static let secondsPerRequest = 0.6

    var images: Int
    var deletes: Int
    var sets: Int

    var requests: Int { images * Self.requestsPerImage + deletes + sets }

    /// Share of the hourly limit, 0–1 (can exceed 1).
    var shareOfHourlyLimit: Double { Double(requests) / Double(Self.hourlyLimit) }

    var minutes: Int { max(1, Int((Double(requests) * Self.secondsPerRequest / 60).rounded())) }

    /// The request count as the summary says it: to the nearest 50 from
    /// 100 up, since it's an estimate.
    var roundedRequests: Int {
        requests < 100 ? requests : Int((Double(requests) / 50).rounded()) * 50
    }

    /// "about 600 requests, 17% of the hourly limit" (584 requests).
    var requestsSummary: String {
        let percent = Int((Double(roundedRequests) / Double(Self.hourlyLimit) * 100).rounded())
        return String(localized: "about \(roundedRequests.formatted()) requests, \(percent)% of the hourly limit")
    }

    /// The estimate for rendering `localeCount` locales × `slotCount` slots
    /// on `displayTypeCount` display types, replacing `liveImages`
    /// screenshots now live in those positions.
    static func scope(localeCount: Int, slotCount: Int, displayTypeCount: Int, liveImages: Int) -> PushCostEstimate {
        PushCostEstimate(
            images: localeCount * slotCount * displayTypeCount,
            deletes: liveImages,
            sets: localeCount * displayTypeCount
        )
    }
}
