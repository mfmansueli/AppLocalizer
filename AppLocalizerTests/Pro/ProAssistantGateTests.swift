//
//  ProAssistantGateTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("ProAssistantGate")
struct ProAssistantGateTests {
    @Test func retentionProposalsNeedPro() {
        for tool in ["propose_retention_message", "propose_retention_offer"] {
            #expect(ProAssistantGate.feature(forTool: tool) == .retention)
            let refusal = ProAssistantGate.refusal(forTool: tool, isPro: false)
            #expect(refusal?.hasPrefix("Retention is part of AppLocalizer Pro") == true)
            #expect(refusal?.contains("go on with the rest") == true)
            #expect(ProAssistantGate.refusal(forTool: tool, isPro: true) == nil)
        }
    }

    @Test func readingAndOneByOneSuggestionsAreFree() {
        for tool in ["get_retention", "get_listing", "suggest_fields", "propose_listing_text", "propose_prices", "next_step", "report_capture"] {
            #expect(ProAssistantGate.refusal(forTool: tool, isPro: false) == nil)
        }
    }
}
