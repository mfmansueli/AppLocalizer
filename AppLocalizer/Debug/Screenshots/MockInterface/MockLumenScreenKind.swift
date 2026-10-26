//
//  MockLumenScreenKind.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Which screen of the sample app a slot's capture shows.
enum MockLumenScreenKind: Int, CaseIterable, Sendable {
    case today
    case week
    case search
    case photo
    case lock

    init(slot: Int) {
        self = Self(rawValue: slot % Self.allCases.count) ?? .today
    }
}
#endif
