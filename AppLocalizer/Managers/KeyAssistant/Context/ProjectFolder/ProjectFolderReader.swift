//
//  ProjectFolderReader.swift
//  AppLocalizer
//

import Foundation

/// Reads a project folder for Generate Suggestions…: `git describe` and
/// `git log` for the commits since the last release tag, or HEAD's reflog
/// when no git binary can run in the sandbox (`/usr/bin/git` is a shim
/// that can't), and CHANGELOG.md.
struct ProjectFolderReader: Sendable {
    /// Xcode's and the Command Line Tools' git are real binaries, unlike
    /// `/usr/bin/git`; Homebrew's next.
    var gitPaths = [
        "/Applications/Xcode.app/Contents/Developer/usr/bin/git",
        "/Library/Developer/CommandLineTools/usr/bin/git",
        "/opt/homebrew/bin/git",
        "/usr/local/bin/git",
        "/usr/bin/git",
    ]

    func read(_ folder: URL, version: String?) async -> ProjectFolderExcerpt {
        var excerpt = ProjectFolderExcerpt()
        guard FileManager.default.fileExists(atPath: folder.path) else {
            excerpt.problem = String(localized: "The project folder can’t be found. Choose it again in Settings → AI Assistants.")
            return excerpt
        }
        let history = gitHistory(in: folder) ?? reflogHistory(in: folder)
        excerpt.tag = history?.tag
        excerpt.commits = history?.subjects ?? []
        let changelog = ["CHANGELOG.md", "Changelog.md", "changelog.md"].lazy
            .compactMap { try? String(contentsOf: folder.appending(path: $0), encoding: .utf8) }
            .first
        excerpt.changelog = changelog.flatMap { ChangelogSection(markdown: $0, version: version) }
        return excerpt
    }

    private func gitHistory(in folder: URL) -> (tag: String?, subjects: [String])? {
        for path in gitPaths where FileManager.default.isExecutableFile(atPath: path) {
            guard run(path, ["-C", folder.path, "rev-parse", "--git-dir"]) != nil else { continue }
            let tag = run(path, ["-C", folder.path, "describe", "--tags", "--abbrev=0"])
            let range = tag.map { ["\($0)..HEAD"] } ?? ["-n", "30"]
            guard let log = run(path, ["-C", folder.path, "log", "--format=%s"] + range) else { continue }
            let subjects = log.split(separator: "\n").map(String.init).reversed()
            return (tag, Array(subjects))
        }
        return nil
    }

    private func reflogHistory(in folder: URL) -> (tag: String?, subjects: [String])? {
        let git = gitDirectory(in: folder)
        guard let reflog = try? String(contentsOf: git.appending(path: "logs/HEAD"), encoding: .utf8) else { return nil }
        var tags = (try? String(contentsOf: git.appending(path: "packed-refs"), encoding: .utf8)).map(GitReflog.tags) ?? [:]
        let tagsFolder = git.appending(path: "refs/tags")
        for name in (try? FileManager.default.contentsOfDirectory(atPath: tagsFolder.path)) ?? [] {
            if let id = try? String(contentsOf: tagsFolder.appending(path: name), encoding: .utf8) {
                tags[id.trimmingCharacters(in: .whitespacesAndNewlines)] = name
            }
        }
        return GitReflog.commitSubjects(reflog: reflog, tags: tags)
    }

    /// `.git`, or where a worktree's `.git` file points.
    private func gitDirectory(in folder: URL) -> URL {
        let dotGit = folder.appending(path: ".git")
        guard let pointer = try? String(contentsOf: dotGit, encoding: .utf8), pointer.hasPrefix("gitdir: ") else { return dotGit }
        let path = pointer.dropFirst("gitdir: ".count).trimmingCharacters(in: .whitespacesAndNewlines)
        return path.hasPrefix("/") ? URL(filePath: path) : folder.appending(path: path)
    }

    /// The command's output, or nil when it failed.
    private func run(_ path: String, _ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(filePath: path)
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return nil }
        // Read before waiting, so a long log can't fill the pipe and stall.
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
