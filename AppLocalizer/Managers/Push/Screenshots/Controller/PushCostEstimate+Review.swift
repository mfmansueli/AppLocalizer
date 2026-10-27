//
//  PushCostEstimate+Review.swift
//  AppLocalizer
//

import Foundation

extension PushCostEstimate {
    /// What pushing the images of `groups` that `isIncluded` lets through
    /// costs: their uploads, the live screenshots they replace (or a
    /// restore removes) and one reorder per set.
    init(groups: [ScreenshotPlanGroup], isIncluded: (ScreenshotPlanItem) -> Bool = { _ in true }) {
        var images = 0
        var deletes = 0
        var sets = 0
        for group in groups {
            let included = group.items.filter(isIncluded)
            guard !included.isEmpty else { continue }
            images += included.count
            deletes += included.count { $0.old != nil } + group.extraLive.count
            sets += 1
        }
        self.init(images: images, deletes: deletes, sets: sets)
    }

    /// "About 168 requests · 2 min · 5% of the hourly limit", plus
    /// `otherRequests` (text changes pushed alongside).
    func reviewText(otherRequests: Int = 0) -> String {
        let total = requests + otherRequests
        let minutes = max(1, Int((Double(total) * Self.secondsPerRequest / 60).rounded()))
        let percent = Int((Double(total) / Double(Self.hourlyLimit) * 100).rounded())
        return String(localized: "About \(total.formatted()) requests · \(minutes) min · \(percent)% of the hourly limit")
    }
}
