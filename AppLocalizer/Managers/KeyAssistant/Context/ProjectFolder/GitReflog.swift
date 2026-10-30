//
//  GitReflog.swift
//  AppLocalizer
//

import Foundation

/// Commit subjects read from a repository's files when git itself can't
/// run: HEAD's reflog (`.git/logs/HEAD`) after the newest line that reached
/// a tagged commit, with the tags from `packed-refs` and `refs/tags`.
enum GitReflog {
    /// Subjects of the commits made after the newest tagged one, oldest
    /// first. Without a tagged commit in the reflog, the last `limit`.
    static func commitSubjects(reflog: String, tags: [String: String], limit: Int = 30) -> (tag: String?, subjects: [String]) {
        var tag: String?
        var subjects: [String] = []
        for line in reflog.split(separator: "\n") {
            guard let entry = entry(String(line)) else { continue }
            if let name = tags[entry.commit] {
                tag = name
                subjects = []
                continue
            }
            guard let kind = entry.message.range(of: ": "), entry.message.hasPrefix("commit") else { continue }
            let subject = String(entry.message[kind.upperBound...]).trimmingCharacters(in: .whitespaces)
            // An amended commit replaces the one before it.
            if entry.message.hasPrefix("commit (amend)"), !subjects.isEmpty { subjects.removeLast() }
            subjects.append(subject)
        }
        return (tag, tag == nil ? Array(subjects.suffix(limit)) : subjects)
    }

    /// Commit → tag name, from `packed-refs`: an annotated tag's peeled
    /// line (`^<commit>`) replaces the tag object's ID.
    static func tags(packedRefs: String) -> [String: String] {
        var tags: [String: String] = [:]
        var last: (object: String, name: String)?
        for line in packedRefs.split(separator: "\n").map(String.init) {
            if line.hasPrefix("^"), let tag = last {
                tags[tag.object] = nil
                tags[String(line.dropFirst())] = tag.name
                last = nil
                continue
            }
            let parts = line.split(separator: " ", maxSplits: 1).map(String.init)
            guard parts.count == 2, parts[1].hasPrefix("refs/tags/") else {
                last = nil
                continue
            }
            let name = String(parts[1].dropFirst("refs/tags/".count))
            tags[parts[0]] = name
            last = (parts[0], name)
        }
        return tags
    }

    /// `<old> <new> <name> <email> <time> <zone>\t<message>`.
    private static func entry(_ line: String) -> (commit: String, message: String)? {
        let halves = line.split(separator: "\t", maxSplits: 1)
        let ids = halves.first?.split(separator: " ") ?? []
        guard halves.count == 2, ids.count >= 2 else { return nil }
        return (String(ids[1]), String(halves[1]))
    }
}
