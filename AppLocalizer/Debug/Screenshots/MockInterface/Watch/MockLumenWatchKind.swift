//
//  MockLumenWatchKind.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// LumenWatch's four screens in the sample plan.
enum MockLumenWatchKind: Int, CaseIterable, Sendable {
    case mood
    case prompt
    case week
    case face

    init(slot: Int) {
        self = Self(rawValue: slot % Self.allCases.count) ?? .mood
    }
}
#endif
