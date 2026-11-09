//
//  RetentionPushOrder.swift
//  AppLocalizer
//

import Foundation

/// App Store Connect refuses a retention offer for a subscription that has
/// no retention message yet (`ENTITY_ERROR.RELATIONSHIP.INVALID`), and the
/// queue keeps the order things were added in. So each app's offers wait
/// for the last of its messages being pushed; everything else stays put.
enum RetentionPushOrder {
    static func sorted(_ changes: [PendingChange]) -> [PendingChange] {
        var messagesLeft: [StoreApp.ID: Int] = [:]
        for change in changes where isMessage(change) {
            messagesLeft[change.appID, default: 0] += 1
        }

        var waiting: [StoreApp.ID: [PendingChange]] = [:]
        var ordered: [PendingChange] = []
        for change in changes {
            if isOffer(change), messagesLeft[change.appID, default: 0] > 0 {
                waiting[change.appID, default: []].append(change)
                continue
            }
            ordered.append(change)
            guard isMessage(change) else { continue }
            messagesLeft[change.appID, default: 0] -= 1
            if messagesLeft[change.appID] == 0 {
                ordered += waiting.removeValue(forKey: change.appID) ?? []
            }
        }
        return ordered
    }

    private static func isMessage(_ change: PendingChange) -> Bool {
        change.id.hasPrefix(RetentionChangeBuilder.messagePrefix)
    }

    private static func isOffer(_ change: PendingChange) -> Bool {
        change.id.hasPrefix(RetentionChangeBuilder.offerPrefix)
    }
}
