//
//  DebugPrivacyDraft.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `info-privacy-draft`: the rest of Claude Code's first scan arriving
/// over a few seconds, through the worksheet store as an MCP call would
/// send it, so the page fills in live.
enum DebugPrivacyDraft {
    @MainActor
    static func stream(into model: AppPrivacyViewModel, every interval: Duration = .milliseconds(1200)) async {
        for (type, suggestion) in DebugPrivacySuggestions.first.dropFirst(5) {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            model.update { $0.propose(suggestion, for: type, at: .now) }
        }
        try? await Task.sleep(for: interval)
        guard !Task.isCancelled else { return }
        model.update { worksheet in
            worksheet.recordScanDetails(DebugPrivacyScan.first, at: .now)
            for question in DebugPrivacySuggestions.questions {
                worksheet.ask(question, at: .now)
            }
            worksheet.finishScan(at: .now)
        }
    }
}
#endif
