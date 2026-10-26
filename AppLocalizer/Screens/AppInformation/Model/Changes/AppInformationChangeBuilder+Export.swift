//
//  AppInformationChangeBuilder+Export.swift
//  AppLocalizer
//

import Foundation

// Export Compliance: the answers add up to one value App Store Connect
// takes per build, `usesNonExemptEncryption`, sent with a `PATCH` of the
// version's build.
extension AppInformationChangeBuilder {
    static let encryptionKey = "encryption"

    var encryptionChangeID: String { versionChangeID(.exportCompliance, Self.encryptionKey) }

    /// Tells the build whether it uses non-exempt encryption. Nil when
    /// there's no build or nothing changed.
    func encryptionChange(_ export: ExportComplianceValues, to answers: ExportComplianceAnswers, source: ChangeSource = .you) -> PendingChange? {
        guard let buildID = export.buildID, let new = answers.usesNonExemptEncryption, new != export.usesNonExemptEncryption else { return nil }
        let title = export.buildNumber.map { String(localized: "Non-exempt encryption · build \($0)") } ?? String(localized: "Non-exempt encryption")
        let answer = { (flag: Bool) in flag ? String(localized: "Yes") : String(localized: "No") }
        return PendingChange(
            id: encryptionChangeID,
            appID: appID,
            section: .appInformation,
            group: group(.exportCompliance),
            title: title,
            oldValue: export.usesNonExemptEncryption.map(answer) ?? String(localized: "Not answered"),
            newValue: answer(new),
            source: source,
            requests: [Self.patch("builds", id: buildID, attributes: ["usesNonExemptEncryption": .bool(new)])],
            restoreRequests: export.usesNonExemptEncryption.map {
                [Self.patch("builds", id: buildID, attributes: ["usesNonExemptEncryption": .bool($0)])]
            } ?? [],
            conflictCheck: Self.attributeCheck(
                "/v1/builds/\(buildID)?fields[builds]=usesNonExemptEncryption",
                key: "usesNonExemptEncryption",
                expected: export.usesNonExemptEncryption.map { AppInformationAPIValue.bool($0).conflictValue } ?? nil
            )
        )
    }

    /// The build's flag with a queued change on top.
    func usesNonExemptEncryption(_ export: ExportComplianceValues, with changes: [PendingChange]) -> Bool? {
        guard let change = Self.change(encryptionChangeID, in: changes) else { return export.usesNonExemptEncryption }
        return Self.document(of: change)?.attribute("usesNonExemptEncryption")?.boolValue
    }
}
