//
//  ChangeSourceFilter.swift
//  AppLocalizer
//

import Foundation

/// The review sheet's "Source" picker: All · You · Machine translation ·
/// one entry per assistant that proposed something.
enum ChangeSourceFilter: Hashable, Sendable {
    case you
    case machineTranslation
    case assistant(String)

    var isAssistant: Bool {
        if case .assistant = self { return true }
        return false
    }

    var title: String {
        switch self {
        case .you: String(localized: "You")
        case .machineTranslation: String(localized: "Machine translation")
        case let .assistant(client): client
        }
    }
}
