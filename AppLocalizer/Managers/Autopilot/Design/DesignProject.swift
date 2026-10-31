//
//  DesignProject.swift
//  AppLocalizer
//

import Foundation

/// The design project an app's screenshots are designed with, as Connect
/// a Design Project stored it.
struct DesignProject: Codable, Hashable, Sendable {
    var kind: DesignProjectKind
    /// The design system or project's name or link
    /// ("Northpier Brand · Claude Design"), a Figma URL, or a folder path.
    var link: String
    /// Also create the directions in Claude Design, to refine them there.
    var createsInClaudeDesign = true
    /// What was found; nil until someone has read it.
    var summary: DesignSourceSummary?

    /// "Northpier Brand", for the strip's pill and the stage list. A web
    /// link nobody has read yet is shortened: a Figma file's name, or its
    /// host and path with long ids cut ("claude.ai/artifact/KxcpHYis…").
    var displayName: String {
        if let title = summary?.title.components(separatedBy: " · ").first, !title.isEmpty { return title }
        let name = link.components(separatedBy: " · ").first ?? link
        if kind == .folder { return URL(filePath: name).lastPathComponent }
        if let short = Self.shortName(ofWebLink: name) { return short }
        return name.isEmpty ? kind.title : name
    }

    /// Path segments longer than this are cut to `idPrefixLength`
    /// characters and "…".
    private static let longSegmentLength = 12
    private static let idPrefixLength = 8

    private static func shortName(ofWebLink link: String) -> String? {
        guard let url = URL(string: link.trimmingCharacters(in: .whitespaces)),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              var host = url.host(), !host.isEmpty
        else { return nil }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        let segments = url.pathComponents.filter { $0 != "/" }
        // figma.com/design/<key>/<File-Name>
        if host.hasSuffix("figma.com"), segments.count >= 3, ["design", "file", "proto", "board", "slides"].contains(segments[0]) {
            let file = segments[2].replacingOccurrences(of: "-", with: " ")
            if !file.isEmpty { return file }
        }
        let path = segments.map { $0.count > longSegmentLength ? String($0.prefix(idPrefixLength)) + "…" : $0 }
        return ([host] + path).joined(separator: "/")
    }
}
