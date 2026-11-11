//
//  AppPrivacyViewModel+Assistant.swift
//  AppLocalizer
//

import Foundation

// "Scan with an assistant": AppLocalizer can't start the assistant, so it
// offers the prompt to paste, then shows the scan as it arrives.
extension AppPrivacyViewModel {
    /// The app's first word, as people say it: "Lumen" for Lumen Journal.
    var appShortName: String {
        app.name.split(separator: " ").first.map(String.init) ?? app.name
    }

    /// What to paste into the assistant, in the project's folder.
    var scanPrompt: String {
        String(localized: """
        Scan this project and propose App Privacy answers for \(app.name) (\(app.bundleID)) through AppLocalizer. \
        Read the privacy manifests, Package.resolved, Info.plist, entitlements and any code that sends data off the \
        device. Use get_privacy_questionnaire for Apple’s terms and send everything with propose_privacy_answers, \
        with evidence and open questions.
        """)
    }

    /// The same request as Claude Code's slash command.
    var scanSlashCommand: String {
        MCPPrompt.fillPrivacyFromCode.slashCommand
    }

    func copyPrompt() {
        copy(scanPrompt)
        isPromptCopied = true
    }

    func copyCommand(_ command: String) {
        copy(command)
        isCommandCopied = true
    }

    /// Copy Prompt was pressed and nothing has arrived yet.
    var isWaitingForScan: Bool {
        isPromptCopied && runningScan == nil && worksheet.scans.isEmpty
    }

    /// "Reading 14 SDKs · 6 privacy manifests · 5 suggestions so far".
    func progressText(of running: PrivacyRunningScan) -> String {
        let sdks = running.scan?.sdks.count ?? 0
        let manifests = running.scan?.manifestsRead.count ?? 0
        let suggestions = running.answeredTypes.count
        if sdks == 0, manifests == 0 {
            return String(localized: "Reading the project · \(suggestions) suggestions so far")
        }
        return String(localized: "Reading \(sdks) SDKs · \(manifests) privacy manifests · \(suggestions) suggestions so far")
    }

    /// "Scan done · 12 answers suggested · 3 open questions".
    func doneText(of scan: PrivacyScan) -> String {
        let answers = scan.suggestionCount == 1 ? String(localized: "1 answer suggested") : String(localized: "\(scan.suggestionCount) answers suggested")
        let questions = scan.questionCount == 1 ? String(localized: "1 open question") : String(localized: "\(scan.questionCount) open questions")
        return String(localized: "Scan done · \(answers) · \(questions)")
    }

    /// "northpier/lumen @ 4f2c91a · Oct 26, 2026 · 10:42 · 14 SDKs · 6 manifests".
    func metaText(of scan: PrivacyScan) -> String {
        let when = scan.ranAt.formatted(date: .abbreviated, time: .shortened)
        let parts = [
            scan.source,
            when,
            scan.sdks.isEmpty ? nil : String(localized: "\(scan.sdks.count) SDKs"),
            scan.manifestsRead.isEmpty ? nil : String(localized: "\(scan.manifestsRead.count) manifests"),
        ]
        return parts.compactMap(\.self).joined(separator: " · ")
    }
}
