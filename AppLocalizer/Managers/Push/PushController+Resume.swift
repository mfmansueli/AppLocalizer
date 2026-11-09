//
//  PushController+Resume.swift
//  AppLocalizer
//

import Foundation

/// A change that stopped partway goes on after what App Store Connect
/// already took, unless it was edited since.
extension PushController {
    /// Keeps how far unfinished changes got, so pushing one again after the
    /// sheet closed doesn't repeat what App Store Connect already took.
    func rememberUnfinished() {
        for item in items {
            if item.status == .done || item.sentRequestCount == 0 {
                unfinished[item.id] = nil
            } else {
                unfinished[item.id] = item
            }
        }
    }

    /// `change` as a new row, resuming where an earlier push of it stopped.
    func resumed(_ change: PendingChange) -> PushItem {
        var item = PushItem(change: change)
        guard let earlier = unfinished.removeValue(forKey: change.id), Self.sentTheSameRequests(earlier, as: change) else { return item }
        item.sentRequestCount = earlier.sentRequestCount
        item.createdID = earlier.createdID
        item.createdIDs = earlier.createdIDs
        return item
    }

    /// `change` still starts with the requests `item` already sent.
    static func sentTheSameRequests(_ item: PushItem, as change: PendingChange) -> Bool {
        let count = item.sentRequestCount
        guard change.pushRequests.count >= count else { return false }
        return Array(change.pushRequests.prefix(count)) == Array(item.change.pushRequests.prefix(count))
    }

    static func forgetProgress(of item: inout PushItem) {
        item.sentRequestCount = 0
        item.createdID = nil
        item.createdIDs = [:]
    }
}
