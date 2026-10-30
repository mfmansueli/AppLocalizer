//
//  GitReflogTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// Commit subjects from HEAD's reflog when git can't run in the sandbox:
/// those after the newest tagged commit, with amends replacing the commit
/// before, and tags from packed-refs.
@Suite("GitReflog")
struct GitReflogTests {
    private func line(_ old: String, _ new: String, _ message: String) -> String {
        "\(old) \(new) Mateus <m@example.dev> 1761800000 +0100\t\(message)"
    }

    @Test func subjectsSinceTheTaggedCommit() {
        let reflog = [
            line("000", "aaa", "commit (initial): Start"),
            line("aaa", "bbb", "commit: Ship 1.3"),
            line("bbb", "ccc", "commit: Add weekly reflections"),
            line("ccc", "ddd", "checkout: moving from main to feature"),
            line("ddd", "eee", "commit: Mood tag"),
            line("eee", "fff", "commit (amend): Mood tags on entries"),
        ].joined(separator: "\n")
        let history = GitReflog.commitSubjects(reflog: reflog, tags: ["bbb": "v1.3"])
        #expect(history.tag == "v1.3")
        #expect(history.subjects == ["Add weekly reflections", "Mood tags on entries"])
    }

    @Test func withoutATagTheLastFew() {
        let reflog = (1...5).map { line("x\($0)", "y\($0)", "commit: Change \($0)") }.joined(separator: "\n")
        let history = GitReflog.commitSubjects(reflog: reflog, tags: [:], limit: 2)
        #expect(history.tag == nil)
        #expect(history.subjects == ["Change 4", "Change 5"])
    }

    @Test func annotatedTagsPointAtTheirCommit() {
        let packed = """
        # pack-refs with: peeled fully-peeled sorted
        111 refs/heads/main
        222 refs/tags/v1.2
        333 refs/tags/v1.3
        ^444
        """
        #expect(GitReflog.tags(packedRefs: packed) == ["222": "v1.2", "444": "v1.3"])
    }
}
