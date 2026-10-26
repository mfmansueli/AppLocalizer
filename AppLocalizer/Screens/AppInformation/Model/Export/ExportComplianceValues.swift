//
//  ExportComplianceValues.swift
//  AppLocalizer
//

import Foundation

/// Export compliance for the shown version: its build, and what App Store
/// Connect says about the build's encryption.
struct ExportComplianceValues: Hashable, Sendable {
    /// The build attached to the version; nil when none is.
    var buildID: String?
    /// The build number, e.g. "42".
    var buildNumber: String?
    var usesNonExemptEncryption: Bool?
    /// The newest encryption declaration's answers, when one was made in
    /// App Store Connect.
    var declaredAnswers: ExportComplianceAnswers?
}
