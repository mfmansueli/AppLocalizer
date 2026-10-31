//
//  ScreenshotsContextWatchTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The screenshots context learns from App Store Connect whether the
/// version's build has an Apple Watch app.
@MainActor
@Suite("ScreenshotsContext · Apple Watch app")
struct ScreenshotsContextWatchTests {
    private struct Failure: Error {}

    private static var context: ScreenshotsContext {
        ScreenshotsContext(primaryLocale: .englishUS, version: ScreenshotsTestFixtures.editableVersion)
    }

    @Test func theVersionsBuildIsAsked() async {
        var context = Self.context
        var asked: [String] = []
        await context.readWatchApp { id in
            asked.append(id)
            return true
        }
        #expect(asked == ["v14"])
        #expect(context.hasWatchApp)
    }

    @Test func aFailureLeavesTheWatchOut() async {
        var context = Self.context
        context.hasWatchApp = true
        await context.readWatchApp { _ in throw Failure() }
        #expect(!context.hasWatchApp)
    }

    @Test func aVersionWithoutAnIDAsksNothing() async {
        var context = ScreenshotsContext(
            primaryLocale: .englishUS,
            version: ScreenshotsVersion(id: nil, versionString: "1.0", stateTitle: "Prepare for Submission", isEditable: true)
        )
        await context.readWatchApp { _ in
            Issue.record("Nothing to ask")
            return true
        }
        #expect(!context.hasWatchApp)
    }
}
