//
//  KeyAssistantTestState.swift
//  AppLocalizer
//

import Foundation

/// The setup's last step with a key: one small request and its answer.
enum KeyAssistantTestState: Hashable, Sendable {
    case idle
    case sending
    /// "Claude Sonnet 5.5 answered in 2.1 s with a subtitle: “…”."
    case works(String)
    case failed(String)

    var isWorking: Bool {
        if case .works = self { return true }
        return false
    }
}
