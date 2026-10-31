//
//  AutopilotError.swift
//  AppLocalizer
//

import Foundation

/// Why Autopilot turned an assistant's report down. The message says how
/// to fix it.
struct AutopilotError: Error, Hashable, Sendable, LocalizedError {
    var message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
