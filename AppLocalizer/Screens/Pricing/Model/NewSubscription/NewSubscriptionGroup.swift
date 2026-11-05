//
//  NewSubscriptionGroup.swift
//  AppLocalizer
//

import Foundation

/// The group a new subscription goes into: one the app has, or a new one
/// the push creates with its display name. Customers can be in one
/// subscription of a group at a time and move between them.
enum NewSubscriptionGroup: Hashable, Sendable {
    case existing(id: String, referenceName: String)
    /// `displayName` is the group's name on the App Store, in the new
    /// subscription's language; App Store Connect needs one to submit it.
    case new(referenceName: String, displayName: String)

    var referenceName: String {
        switch self {
        case let .existing(_, name), let .new(name, _): name
        }
    }

    var isNew: Bool {
        if case .new = self { return true }
        return false
    }
}
