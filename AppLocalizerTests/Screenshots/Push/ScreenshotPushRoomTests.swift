//
//  ScreenshotPushRoomTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A set holds 10 screenshots, and new images stand beside the ones they
/// replace until Apple processes them. Alba's 1.1.0 push had 5 live and 6
/// new in each set: the 5 replacements filled it to 10, and the sixth,
/// which replaced nothing, failed in all 14 languages.
@MainActor
@Suite("ScreenshotPushRun · room in the set")
struct ScreenshotPushRoomTests {
    private typealias Fixtures = ScreenshotPushTestFixtures

    /// Five live, six new: five replace, the sixth adds.
    private static let fiveLiveSixNew = Fixtures.plan([
        Fixtures.group(.german, live: Fixtures.liveSet(.german, count: 5), slots: Array(0..<6)),
    ])

    @Test func anAddedImageWaitsForTheReplacedOnesToGo() async throws {
        let transport = FakeScreenshotUploadTransport()
        let run = await Fixtures.push([Self.fiveLiveSixNew], environment: Fixtures.environment(transport))

        #expect(run.doneCount == 6)
        let log = transport.log
        let added = try #require(log.firstIndex { $0.hasPrefix("reserve de-DE_iPhone_6_") })
        for slot in 0..<5 {
            let deleted = try #require(log.firstIndex(of: "delete live-de-DE-\(slot)"), "Old screenshot \(slot + 1) goes")
            #expect(deleted < added, "Before the sixth is reserved")
        }
        #expect(run.items.allSatisfy { $0.note == nil })
    }

    @Test func stillProcessingTheSetStaysFullAndTheAddedImageFails() async throws {
        let checks = Dictionary(uniqueKeysWithValues: (1...5).map { ("de-DE_iPhone_\($0)_", 100) })
        let transport = FakeScreenshotUploadTransport(.init(processingChecks: checks))
        var environment = Fixtures.environment(transport)
        environment.deliveryChecks = 2
        let run = await Fixtures.push([Self.fiveLiveSixNew], environment: environment)

        let added = try #require(run.items.last)
        #expect(added.status.failureText == "The set already has 10 screenshots. Nothing was added to the set.")
        #expect(!transport.log.contains { $0.hasPrefix("reserve de-DE_iPhone_6_") })
        #expect(!transport.log.contains { $0.hasPrefix("delete live-de-DE-") }, "The old ones stay beside the new ones")
        #expect(run.doneCount == 5)
    }

    @Test func aSetWithRoomAddsWithoutWaiting() async throws {
        let plan = Fixtures.plan([Fixtures.group(.german, live: Fixtures.liveSet(.german, count: 2), slots: [0, 1, 2])])
        let transport = FakeScreenshotUploadTransport()
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport))

        #expect(run.doneCount == 3)
        let log = transport.log
        let added = try #require(log.firstIndex { $0.hasPrefix("reserve de-DE_iPhone_3_") })
        let firstDelete = try #require(log.firstIndex { $0.hasPrefix("delete live-de-DE-") })
        #expect(added < firstDelete, "Old ones go at the end, as before")
    }
}
#endif
