//
//  ClaudeCodeProjectFolderCheckTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The project folder Claude Code starts in builds the app: MB Admin's Open
/// panel opened in Bruma's folder, where Claude Code would have captured
/// the wrong app.
@MainActor
@Suite("ClaudeCodeLauncher · the folder builds the app")
struct ClaudeCodeProjectFolderCheckTests {
    private let assistants = MCPTestFixtures.controller()
    private static let bruma = "/Users/sam/Projects/ios/Bruma"
    private static let mbAdmin = "/Users/sam/Projects/ios/MB-Admin"

    /// MB Admin's launcher: Bruma's folder already chosen for Bruma, and
    /// the folders' projects as given.
    private func launcher(choosing folders: [String?], builds: [String: [String]], usesAnyway: Bool = false)
        -> (ClaudeCodeLauncher, ClaudeCodeTestFixtures.FolderRequests, () -> Int)
    {
        let asked = ClaudeCodeTestFixtures.FolderRequests()
        let launcher = ClaudeCodeTestFixtures.launcher(assistants: assistants, asked: asked)
        launcher.setProjectFolder(Self.bruma, for: ClaudeCodeTestFixtures.lumenID)
        var answers = folders
        launcher.folderChooser = { appName, suggestion in
            asked.requests.append((appName, suggestion))
            return answers.isEmpty ? nil : answers.removeFirst()
        }
        launcher.bundleIDLookup = { $0 == ClaudeCodeTestFixtures.tempoID ? "br.com.mbadmin" : nil }
        launcher.folderChecker = { ProjectFolderCheck(bundleIDs: builds[$0] ?? [], hasVariables: false) }
        var alerts = 0
        launcher.mismatchConfirmer = { _, _, _ in
            alerts += 1
            return usesAnyway
        }
        return (launcher, asked, { alerts })
    }

    @Test func anotherAppsFolderIsAskedAboutAndThePanelOpensAgain() {
        let (launcher, asked, alerts) = launcher(
            choosing: [Self.bruma, Self.mbAdmin],
            builds: [Self.bruma: ["com.lima.bruma"], Self.mbAdmin: ["br.com.mbadmin", "br.com.mbadmin.LiveActivity"]]
        )
        let folder = launcher.chooseProjectFolder(for: ClaudeCodeTestFixtures.tempoID, appName: "MB Admin")
        #expect(folder == Self.mbAdmin)
        #expect(alerts() == 1)
        #expect(asked.requests.count == 2)
        // The second panel opens beside the wrong folder.
        #expect(asked.requests.last?.suggestion == "/Users/sam/Projects/ios/")
        #expect(launcher.projectFolder(for: ClaudeCodeTestFixtures.tempoID) == Self.mbAdmin)
    }

    @Test func thePersonCanUseItAnyway() {
        let (launcher, _, alerts) = launcher(choosing: [Self.bruma], builds: [Self.bruma: ["com.lima.bruma"]], usesAnyway: true)
        #expect(launcher.chooseProjectFolder(for: ClaudeCodeTestFixtures.tempoID, appName: "MB Admin") == Self.bruma)
        #expect(alerts() == 1)
    }

    @Test func aFolderThatCantBeToldIsntHeldAgainstThem() {
        let (launcher, _, alerts) = launcher(choosing: ["/Users/sam/Elsewhere"], builds: [:])
        #expect(launcher.chooseProjectFolder(for: ClaudeCodeTestFixtures.tempoID, appName: "MB Admin") == "/Users/sam/Elsewhere")
        #expect(alerts() == 0)
    }

    @Test func thePanelDoesntOpenInsideAnotherAppsProject() {
        let (launcher, asked, _) = launcher(choosing: [nil], builds: [:])
        var paired = MCPTestFixtures.pair(.claudeCode, in: assistants, at: .now).client
        paired.workingDirectory = Self.bruma
        assistants.restorePairings([paired], tokens: assistants.tokens)

        #expect(launcher.suggestedFolder(for: ClaudeCodeTestFixtures.tempoID) == Self.bruma)
        #expect(launcher.panelFolder(for: ClaudeCodeTestFixtures.tempoID) == "/Users/sam/Projects/ios/")
        #expect(launcher.panelFolder(for: ClaudeCodeTestFixtures.lumenID) == Self.bruma, "Its own folder")
        #expect(launcher.chooseProjectFolder(for: ClaudeCodeTestFixtures.tempoID, appName: "MB Admin") == nil)
        #expect(asked.requests.first?.suggestion == "/Users/sam/Projects/ios/")
    }

    // MARK: - Reading the projects

    @Test func theBundleIDsAreReadFromTheProjectFile() {
        let text = """
                PRODUCT_BUNDLE_IDENTIFIER = br.com.mbadmin;
                PRODUCT_BUNDLE_IDENTIFIER = "br.com.mbadmin.MB-AdminTests";
                PRODUCT_BUNDLE_IDENTIFIER = br.com.mbadmin.LiveActivity;
                PRODUCT_NAME = "$(TARGET_NAME)";
        """
        let ids = ProjectFolderCheck.bundleIDs(inProjectFile: text)
        #expect(ids == ["br.com.mbadmin", "br.com.mbadmin.MB-AdminTests", "br.com.mbadmin.LiveActivity"])
        let check = ProjectFolderCheck(bundleIDs: ids.sorted(), hasVariables: false)
        #expect(check.appBundleIDs == ["br.com.mbadmin"])
        #expect(check.builds("br.com.mbadmin"))
        #expect(!check.builds("com.lima.bruma"))
        #expect(ProjectFolderCheck(bundleIDs: ["x"], hasVariables: true).builds("com.lima.bruma"), "Can't tell")
    }

    @Test func aFolderOnDiskIsReadTwoLevelsDown() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "folder-check-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let project = root.appending(path: "App/Bruma.xcodeproj")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        try "PRODUCT_BUNDLE_IDENTIFIER = com.lima.bruma;\n".write(to: project.appending(path: "project.pbxproj"), atomically: true, encoding: .utf8)
        let built = root.appending(path: "build/Old.xcodeproj")
        try FileManager.default.createDirectory(at: built, withIntermediateDirectories: true)
        try "PRODUCT_BUNDLE_IDENTIFIER = com.old;\n".write(to: built.appending(path: "project.pbxproj"), atomically: true, encoding: .utf8)

        let check = ProjectFolderCheck.check(folder: root.path(percentEncoded: false))
        #expect(check.bundleIDs == ["com.lima.bruma"], "Build products are skipped")
        #expect(ProjectFolderCheck.check(folder: root.appending(path: "missing").path(percentEncoded: false)).bundleIDs.isEmpty)
    }
}
