//
//  XcresultTimeline.swift
//  AppLocalizer
//

import Foundation

/// Reads `xcrun xcresulttool get test-results`' JSON: the tests a result
/// bundle ran (`tests`), and when each took the screenshots it attached
/// (`activities`, one test at a time).
enum XcresultTimeline {
    /// Each test case's identifier, e.g. `ScreenshotUITests/testStreak()`.
    static func testIDs(in data: Data) -> [String] {
        guard let tests = try? JSONDecoder().decode(Tests.self, from: data) else { return [] }
        var ids: [String] = []
        func walk(_ node: Node) {
            if node.nodeType == "Test Case", let id = node.nodeIdentifier { ids.append(id) }
            node.children?.forEach(walk)
        }
        tests.testNodes.forEach(walk)
        return ids
    }

    /// One test's screenshots, in the order it attached them: each
    /// attachment's time, and when the step before it started.
    static func screenshots(in data: Data) -> [TestScreenshot] {
        guard let activities = try? JSONDecoder().decode(Activities.self, from: data) else { return [] }
        var screenshots: [TestScreenshot] = []
        for run in activities.testRuns {
            var steps: [Double] = []
            var attached: [(name: String, time: Double)] = []
            func walk(_ activity: Activity) {
                let own = (activity.attachments ?? []).filter { isTestsOwn($0, of: activity) }
                if !own.isEmpty {
                    for attachment in own {
                        guard let time = attachment.timestamp ?? activity.startTime else { continue }
                        attached.append((name(of: activity, attachment: attachment), time))
                    }
                    return
                }
                // A step XCTest attached its own record to (a tap's
                // synthesized event) is a step like any other.
                if let start = activity.startTime { steps.append(start) }
                activity.childActivities?.forEach(walk)
            }
            run.activities?.forEach(walk)
            for (name, time) in attached {
                screenshots.append(TestScreenshot(
                    test: activities.testIdentifier ?? "", name: name, time: time,
                    readySince: steps.filter { $0 < time }.max(), deviceID: run.device?.deviceId
                ))
            }
        }
        return screenshots.sorted { $0.time < $1.time }
    }

    /// XCTest's own attachments, which aren't the test's screenshots.
    static let automaticPrefixes = [
        "Synthesized Event", "UI Snapshot", "Screen Recording", "App UI hierarchy", "Complete Issue Description",
        "Debug description", "kXCTAttachment",
    ]

    /// An image the test attached: not one XCTest adds by itself (MB Admin's
    /// iPhone Duo run had 40 of them, "Synthesized Event …", "UI Snapshot
    /// …", a screen recording and texts, each made into a full-size capture
    /// for Claude Code to look at).
    private static func isTestsOwn(_ attachment: Attachment, of activity: Activity) -> Bool {
        let file = attachment.name ?? ""
        let type = (file as NSString).pathExtension.lowercased()
        guard type.isEmpty || ["png", "jpg", "jpeg", "heic"].contains(type) else { return false }
        let name = name(of: activity, attachment: attachment)
        return !automaticPrefixes.contains { name.hasPrefix($0) || file.hasPrefix($0) }
    }

    /// "Added attachment named 'streak'", or its file's name without the
    /// `_0_<UUID>.png` XCTest adds.
    private static func name(of activity: Activity, attachment: Attachment) -> String {
        let prefix = "Added attachment named '"
        if let title = activity.title, title.hasPrefix(prefix), title.hasSuffix("'"), title.count > prefix.count + 1 {
            return String(title.dropFirst(prefix.count).dropLast())
        }
        let file = attachment.name ?? ""
        if let range = file.range(of: #"_\d+_[0-9A-F-]{36}\.\w+$"#, options: .regularExpression) {
            return String(file[..<range.lowerBound])
        }
        return file
    }

    // MARK: - The JSON

    private struct Tests: Decodable {
        var testNodes: [Node]
    }

    private struct Node: Decodable {
        var nodeType: String?
        var nodeIdentifier: String?
        var children: [Node]?
    }

    private struct Activities: Decodable {
        var testIdentifier: String?
        var testRuns: [Run]
    }

    private struct Run: Decodable {
        var device: Device?
        var activities: [Activity]?
    }

    private struct Device: Decodable {
        var deviceId: String?
    }

    private struct Activity: Decodable {
        var title: String?
        var startTime: Double?
        var attachments: [Attachment]?
        var childActivities: [Activity]?
    }

    private struct Attachment: Decodable {
        var name: String?
        var timestamp: Double?
    }
}
