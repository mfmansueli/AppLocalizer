//
//  ArtworkLoopIndex.swift
//  AppLocalizer
//

import Foundation

/// The loops made before, by the poster they move: the same poster from
/// the same loop maker makes the same loop, so a resumed or repeated run
/// keeps it instead of drawing 600 frames again. Kept beside the files, in
/// the app's Extras folder.
struct ArtworkLoopIndex: Codable, Hashable, Sendable {
    var loops: [String: ExtrasArtworkLoop] = [:]

    static let fileName = "loop-index.json"

    /// A poster's key: its checksum and the loop maker's version.
    static func key(poster: String, version: Int = ArtworkLoopRenderer.version) -> String {
        "\(poster)-v\(version)"
    }

    func loop(forPoster poster: String, version: Int = ArtworkLoopRenderer.version) -> ExtrasArtworkLoop? {
        loops[Self.key(poster: poster, version: version)]
    }

    mutating func remember(_ loop: ExtrasArtworkLoop, forPoster poster: String, version: Int = ArtworkLoopRenderer.version) {
        loops[Self.key(poster: poster, version: version)] = loop
    }

    /// The index in `folder`; empty when there's none or it can't be read.
    static func load(from folder: URL) -> ArtworkLoopIndex {
        guard let data = try? Data(contentsOf: folder.appending(path: fileName)),
              let index = try? JSONDecoder().decode(ArtworkLoopIndex.self, from: data)
        else { return ArtworkLoopIndex() }
        return index
    }

    func save(to folder: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(self).write(to: folder.appending(path: Self.fileName), options: .atomic)
    }
}
