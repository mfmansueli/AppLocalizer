//
//  AppInformationNotes.swift
//  AppLocalizer
//

import Foundation

/// What App Information keeps on this Mac for one app because App Store
/// Connect has nowhere for it: the override's reason, the export compliance
/// answers, and assistants' evidence and suggestions. Never secrets: the
/// demo password lives in the Keychain.
struct AppInformationNotes: Hashable, Codable, Sendable {
    /// Why the app is rated higher than calculated.
    var overrideReason = ""
    var exportAnswers: ExportComplianceAnswers?
    /// Evidence for assistant answers, by `AgeRatingQuestion` raw value.
    var ageEvidence: [String: AssistantEvidence] = [:]
    var exportEvidence: AssistantEvidence?
    /// Suggestions by `DeviceFamily` raw value.
    var accessibilitySuggestions: [String: [AccessibilitySuggestion]] = [:]
    /// The app's common tasks, for the accessibility editor's bar, e.g.
    /// "writing an entry", "finding one".
    var commonTasks: [String] = []
}

// Every field is optional when decoding, so notes saved before a field
// existed still load.
extension AppInformationNotes {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        overrideReason = try container.decodeIfPresent(String.self, forKey: .overrideReason) ?? ""
        exportAnswers = try container.decodeIfPresent(ExportComplianceAnswers.self, forKey: .exportAnswers)
        ageEvidence = try container.decodeIfPresent([String: AssistantEvidence].self, forKey: .ageEvidence) ?? [:]
        exportEvidence = try container.decodeIfPresent(AssistantEvidence.self, forKey: .exportEvidence)
        accessibilitySuggestions = try container.decodeIfPresent([String: [AccessibilitySuggestion]].self, forKey: .accessibilitySuggestions) ?? [:]
        commonTasks = try container.decodeIfPresent([String].self, forKey: .commonTasks) ?? []
    }
}
