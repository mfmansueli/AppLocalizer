//
//  ScreenshotPushRun+Delivery.swift
//  AppLocalizer
//

import Foundation

/// Apple accepts a committed file and processes it afterwards, and can
/// still fail it then. A set's new images are checked together, since
/// Apple processes them side by side, before what they replace is deleted.
extension ScreenshotPushRun {
    /// Waits for the set's committed images: a processed one can replace
    /// the old screenshot; a failed one becomes a failed row. One still
    /// processing when the checks run out keeps the old screenshot beside
    /// it (`finishSet`).
    func confirmDelivery(_ groupID: String) async {
        var waiting = items.indices.filter { index in
            let item = items[index]
            return item.groupID == groupID && item.isCommitted && !item.isDeliveryConfirmed && item.screenshotID != nil
        }
        var check = 0
        while !waiting.isEmpty, check < environment.deliveryChecks {
            if check > 0 { try? await environment.sleep(environment.deliveryInterval) }
            check += 1
            var stillWaiting: [Int] = []
            for index in waiting where await isStillProcessing(index) {
                stillWaiting.append(index)
            }
            waiting = stillWaiting
        }
    }

    /// One check of one image; a check that can't be read counts as still
    /// processing.
    private func isStillProcessing(_ index: Int) async -> Bool {
        guard let id = items[index].screenshotID,
              let response = try? await fetch(ScreenshotUploadRequests.statusPath(screenshotID: id)),
              let delivery = ScreenshotUploadRequests.deliveryState(in: response.data) else { return true }
        if delivery.isFailed {
            items[index].isCommitted = false
            await dropReservation(index)
            let failure = ScreenshotPushFailure.processing(code: delivery.errorCode ?? delivery.state)
            noteFailure(index, failure, replaces: showsLive(index))
            return false
        }
        guard delivery.isComplete else { return true }
        items[index].isDeliveryConfirmed = true
        return false
    }
}
