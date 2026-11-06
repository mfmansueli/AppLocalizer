//
//  ProjectFolderCheck.swift
//  AppLocalizer
//

import Foundation

/// Whether a chosen project folder builds the app: the bundle IDs its
/// Xcode projects set, read from each `project.pbxproj` up to two folders
/// down. MB Admin's Open panel opened in Bruma's folder (the last one
/// Claude Code worked in); choosing it would have captured the wrong app.
struct ProjectFolderCheck: Hashable, Sendable {
    /// Every literal `PRODUCT_BUNDLE_IDENTIFIER` found, sorted.
    var bundleIDs: [String]
    /// Some identifier is built from a setting (`$(BASE_ID).app`), so
    /// what it builds can't be told from the file.
    var hasVariables: Bool

    /// True unless the folder's projects plainly build other apps. A folder
    /// with no readable project, or with identifiers from settings, isn't
    /// held against the person.
    func builds(_ bundleID: String) -> Bool {
        bundleIDs.isEmpty || hasVariables || bundleIDs.contains(bundleID)
    }

    /// The app identifiers among `bundleIDs`: the shortest of each family,
    /// so "com.lima.bruma" stands for its widget and tests too.
    var appBundleIDs: [String] {
        bundleIDs.filter { id in !bundleIDs.contains { $0 != id && id.hasPrefix($0 + ".") } }
    }

    /// Reads `folder`'s projects. A folder that can't be read checks as
    /// having none.
    static func check(folder: String, fileManager: FileManager = .default) -> ProjectFolderCheck {
        var ids: Set<String> = []
        var hasVariables = false
        for project in projects(in: URL(filePath: folder, directoryHint: .isDirectory), depth: 2, fileManager: fileManager) {
            guard let text = try? String(contentsOf: project.appending(path: "project.pbxproj"), encoding: .utf8) else { continue }
            let found = bundleIDs(inProjectFile: text)
            hasVariables = hasVariables || found.contains { $0.contains("$") }
            ids.formUnion(found.filter { !$0.contains("$") })
        }
        return ProjectFolderCheck(bundleIDs: ids.sorted(), hasVariables: hasVariables)
    }

    /// `PRODUCT_BUNDLE_IDENTIFIER = br.com.mbadmin;` and its quoted form.
    static func bundleIDs(inProjectFile text: String) -> Set<String> {
        var ids: Set<String> = []
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("PRODUCT_BUNDLE_IDENTIFIER"), let equals = trimmed.firstIndex(of: "=") else { continue }
            let value = trimmed[trimmed.index(after: equals)...]
                .trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ";\"")))
            if !value.isEmpty { ids.insert(value) }
        }
        return ids
    }

    /// The `.xcodeproj` packages in `folder` and up to `depth` folders
    /// below it, skipping hidden folders and build products.
    private static func projects(in folder: URL, depth: Int, fileManager: FileManager) -> [URL] {
        let skipped: Set = ["build", "DerivedData", "Pods", "node_modules", "Carthage"]
        guard let items = try? fileManager.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        ) else { return [] }
        var projects: [URL] = []
        for item in items where (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            if item.pathExtension == "xcodeproj" {
                projects.append(item)
            } else if depth > 0, !skipped.contains(item.lastPathComponent), item.pathExtension.isEmpty {
                projects += self.projects(in: item, depth: depth - 1, fileManager: fileManager)
            }
        }
        return projects
    }
}
