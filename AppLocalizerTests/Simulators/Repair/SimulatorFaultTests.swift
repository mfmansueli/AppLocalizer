//
//  SimulatorFaultTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("SimulatorFault")
struct SimulatorFaultTests {
    /// What Alba's run reported for each device.
    @Test func theStuckAudioServiceIsReadFromSimctlsError() {
        let said = """
        iPhone 17 Pro Max won't boot on this Mac right now: xcrun simctl boot and xcodebuild test both fail with \
        "Bundle com.apple.CoreSimulator.SimAudioProcessorServices failed to create an audio route descriptor" (Input/output error).
        """
        #expect(SimulatorFault.matching(said) == .audioService)
        #expect(SimulatorFault.matching("failed to create an AUDIO ROUTE DESCRIPTOR") == .audioService)
    }

    @Test func aStartThatFailsOtherwiseIsTheSimulatorService() {
        #expect(SimulatorFault.matching("Unable to boot device in current state: Shutdown") == .simulatorService)
        #expect(SimulatorFault.matching("CoreSimulatorService connection became invalid. Simulator services will no longer be available.") == .simulatorService)
        #expect(SimulatorFault.matching("iPad Pro 13-inch (M5) won’t boot on this Mac") == .simulatorService)
    }

    @Test func otherProblemsArentFaults() {
        #expect(SimulatorFault.matching("The photo picker asked for access and covered the entry.") == nil)
        #expect(SimulatorFault.matching("This Mac can’t run the iPhone Duo simulator. Needs the iOS 27.2 simulator or later.") == nil)
        #expect(SimulatorFault.matching("") == nil)
    }

    @Test func eachSaysWhatsWrongInPlainWords() {
        for fault in SimulatorFault.allCases {
            #expect(fault.summary.hasSuffix("so no simulator can start."))
            #expect(!fault.summary.contains("sudo"))
        }
    }
}
