//
//  AssistantSetupStep.swift
//  AppLocalizer
//

import Foundation

/// The four steps of "Set Up Your AI Assistant".
enum AssistantSetupStep: Int, CaseIterable, Identifiable, Comparable, Sendable {
    case assistant = 1
    case server
    case snippet
    case test

    var id: Self { self }

    /// The label under the step's bar.
    var title: String {
        switch self {
        case .assistant: String(localized: "Assistant")
        case .server: String(localized: "Local server")
        case .snippet: String(localized: "Add to assistant")
        case .test: String(localized: "Test")
        }
    }

    var next: AssistantSetupStep? { AssistantSetupStep(rawValue: rawValue + 1) }
    var previous: AssistantSetupStep? { AssistantSetupStep(rawValue: rawValue - 1) }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}
