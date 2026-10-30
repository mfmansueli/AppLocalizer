//
//  ProjectFolderExcerpt.swift
//  AppLocalizer
//

import Foundation

/// What a request may include from the project folder: commit subjects
/// since the last release tag, and CHANGELOG.md's section for the version.
/// Nothing else is read, and source code is never sent.
struct ProjectFolderExcerpt: Hashable, Sendable {
    /// "v1.3"; nil when no tag was found.
    var tag: String?
    var commits: [String] = []
    var changelog: ChangelogSection?
    /// Why the folder couldn't be read, e.g. it moved.
    var problem: String?
}
