//
//  AutopilotRunClientNameTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// Who the sheet says runs the capture.
@MainActor
@Suite("AutopilotRun.clientName")
struct AutopilotRunClientNameTests {
    @Test(arguments: [
        (String?("Claude Code"), String?("Codex"), false, "Claude Code"),
        (nil, "Codex", false, "Codex"),
        (nil, nil, false, "your assistant"),
        (nil, nil, true, "Your assistant"),
        ("Cursor", nil, true, "Cursor"),
    ])
    func theClientThenTheAssistantThenYourAssistant(client: String?, assistant: String?, startsSentence: Bool, name: String) {
        var run = StudioDebugRuns.run(.waiting)
        run.client = client
        #expect(run.clientName(assistant: assistant, startsSentence: startsSentence) == name)
    }
}
#endif
