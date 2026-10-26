//
//  AssistantDebugScenesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// Every `ai-*` scene opens a view, and the streamed proposals are
/// Claude Code's.
@MainActor
@Suite("AssistantDebugScenes")
struct AssistantDebugScenesTests {
    @Test(arguments: AssistantDebugScenes.ids)
    func everySceneHasAView(id: String) {
        #expect(AssistantDebugScenes.view(for: id) != nil)
    }

    @Test func unknownIDsAreLeftToOtherSections() {
        #expect(AssistantDebugScenes.view(for: "set-ai-on") == nil)
    }

    /// Eleven field proposals, plus Korean's name, subtitle and privacy
    /// URL, which create the new localization in one change.
    @Test func streamedProposalsComeFromClaudeCode() {
        let proposals = AssistantDebugScenes.streamedProposals
        #expect(proposals.count == 12)
        #expect(proposals.allSatisfy { $0.source == .assistant(client: "Claude Code") })
        #expect(AssistantActivity(workingClient: nil, changes: proposals).proposalCount == 12)
    }
}
#endif
