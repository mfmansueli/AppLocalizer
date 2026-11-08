//
//  GuidedMacCheckTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Plan · This Mac: one row per device in the run, what holds Start
/// Autopilot (a simulator to make or install, a helper too old to check),
/// and what doesn't (iPhone Duo starting closed).
@Suite("Guided Autopilot · This Mac")
struct GuidedMacCheckTests {
    private static func inventory(newRuntime: Bool = false, duo: Bool = false) throws -> SimulatorInventory {
        try SimulatorInventory.parse(DebugSimulators.json(DebugSimulators.Mac(hasNewRuntime: newRuntime, hasDuo: duo)))
    }

    @Test func everySimulatorThereLetsStartGo() throws {
        let check = try GuidedMacCheck(displays: [.iPhone, .iPad, .watch], state: .checked(Self.inventory()))
        #expect(check.missing.isEmpty)
        #expect(!check.blocksStart)
        #expect(check.summary == "Ready")
        #expect(!check.summaryIsWarning)
    }

    @Test func aSimulatorToMakeHoldsStart() throws {
        // iOS 27.2 is installed but no iPhone Duo simulator is made yet.
        let check = try GuidedMacCheck(displays: [.iPhone, .iPhoneDuo], state: .checked(Self.inventory(newRuntime: true)))
        #expect(check.missing == [.iPhoneDuo])
        #expect(check.blocksStart)
        #expect(check.summary == "1 simulator to make before Start")
        #expect(check.detail(for: .iPhoneDuo, appName: "Lumen") == "No iPhone Duo simulator yet. It can be made on iOS 27.2 in a few seconds.")
    }

    @Test func aPlatformToInstallHoldsStartToo() throws {
        let check = try GuidedMacCheck(displays: [.iPhone, .iPhoneDuo, .visionPro], state: .checked(Self.inventory()))
        #expect(check.missing == [.iPhoneDuo, .visionPro])
        #expect(check.blocksStart)
        #expect(check.summary == "2 simulators to set up before Start")
    }

    @Test func iPhoneDuoClosedIsNotMissing() throws {
        let check = try GuidedMacCheck(displays: [.iPhone, .iPhoneDuo], state: .checked(Self.inventory(newRuntime: true, duo: true)))
        #expect(check.missing.isEmpty, "It starts closed and AppLocalizer opens it when the run needs it")
        #expect(!check.blocksStart)
    }

    @Test func anOlderHelperCantCheckSoStartWaits() {
        let check = GuidedMacCheck(displays: [.iPhone], state: .oldHelper)
        #expect(check.helperCantCheck)
        #expect(check.blocksStart)
        #expect(check.summary == "Can’t check this Mac yet")
    }

    @Test(arguments: [MacSimulators.State.unknown, .checking, .noHelper, .failed("No Xcode")])
    func whatIsntKnownDoesntHoldStart(state: MacSimulators.State) {
        #expect(!GuidedMacCheck(displays: [.iPhone], state: state).blocksStart)
    }

    @Test func aRunWithoutCapturesHasNoRows() throws {
        let check = try GuidedMacCheck(displays: [], state: .checked(Self.inventory()))
        #expect(!check.blocksStart)
        #expect(GuidedMacCheck(displays: [], state: .oldHelper).blocksStart == false)
    }

    @Test func theMacRowSaysTheAppRunsHere() throws {
        let check = try GuidedMacCheck(displays: [.iPhone, .mac], state: .checked(Self.inventory()))
        #expect(check.detail(for: .mac, appName: "Lumen") == "This Mac · Lumen for Mac runs here directly")
        #expect(check.detail(for: .iPhone, appName: "Lumen") == "iPhone 17 Pro Max · iOS 27.0")
        #expect(!check.blocksStart)
    }
}
#endif
