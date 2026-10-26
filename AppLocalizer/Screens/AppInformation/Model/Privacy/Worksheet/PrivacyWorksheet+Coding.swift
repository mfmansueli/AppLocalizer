//
//  PrivacyWorksheet+Coding.swift
//  AppLocalizer
//

import Foundation

// Every field is optional when decoding, so a worksheet saved before a
// field existed still loads.
extension PrivacyWorksheet {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        collects = try container.decodeIfPresent(PrivacyCollectsAnswer.self, forKey: .collects)
        entries = try container.decodeIfPresent([PrivacyDataType: PrivacyTypeEntry].self, forKey: .entries) ?? [:]
        questions = try container.decodeIfPresent([PrivacyOpenQuestion].self, forKey: .questions) ?? []
        scans = try container.decodeIfPresent([PrivacyScan].self, forKey: .scans) ?? []
        runningScan = try container.decodeIfPresent(PrivacyRunningScan.self, forKey: .runningScan)
        manifestDeclarations = try container.decodeIfPresent([PrivacyDataType: [String]].self, forKey: .manifestDeclarations) ?? [:]
        explanations = try container.decodeIfPresent([PrivacyDataType: String].self, forKey: .explanations) ?? [:]
        checkedSteps = try container.decodeIfPresent(Set<String>.self, forKey: .checkedSteps) ?? []
        publication = try container.decodeIfPresent(PrivacyPublication.self, forKey: .publication)
        isStarted = try container.decodeIfPresent(Bool.self, forKey: .isStarted) ?? false
    }
}
