//
//  AutopilotRun+ClientName.swift
//  AppLocalizer
//

import Foundation

extension AutopilotRun {
    /// Who runs the capture: the client that picked the run up, else the
    /// connected assistant that can run Xcode, else "your assistant"
    /// ("Your assistant" when it starts a sentence).
    func clientName(assistant: String?, startsSentence: Bool = false) -> String {
        if let name = client ?? assistant { return name }
        return startsSentence ? String(localized: "Your assistant") : String(localized: "your assistant")
    }
}
