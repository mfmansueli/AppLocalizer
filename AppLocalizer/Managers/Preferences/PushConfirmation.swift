//
//  PushConfirmation.swift
//  AppLocalizer
//

import Foundation

/// Settings → General → "Confirm before pushing".
enum PushConfirmation: String, CaseIterable, Identifiable, Sendable {
    case always
    case overFifty
    case never

    var id: String { rawValue }

    var title: String {
        switch self {
        case .always: String(localized: "Always")
        case .overFifty: String(localized: "Over 50 changes")
        case .never: String(localized: "Never")
        }
    }

    func requiresConfirmation(changeCount: Int) -> Bool {
        switch self {
        case .always: changeCount > 0
        case .overFifty: changeCount > 50
        case .never: false
        }
    }
}
