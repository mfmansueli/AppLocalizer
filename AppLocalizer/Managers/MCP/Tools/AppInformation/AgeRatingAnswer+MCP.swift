//
//  AgeRatingAnswer+MCP.swift
//  AppLocalizer
//

import Foundation

extension AgeRatingAnswer {
    /// The answer an assistant means: none, infrequent, frequent, no or
    /// yes (also true and false), ignoring case.
    static func matching(_ value: JSONValue) -> AgeRatingAnswer? {
        if let bool = value.boolValue { return bool ? .affirmative : .negative }
        switch value.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "none": return AgeRatingAnswer.none
        case "infrequent", "infrequent_or_mild": return .infrequent
        case "frequent", "frequent_or_intense": return .frequent
        case "no", "false", "negative": return .negative
        case "yes", "true", "affirmative": return .affirmative
        default: return nil
        }
    }
}
