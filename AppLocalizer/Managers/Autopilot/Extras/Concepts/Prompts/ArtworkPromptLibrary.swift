//
//  ArtworkPromptLibrary.swift
//  AppLocalizer
//

import Foundation

/// Reads the prompts' resource files, once.
enum ArtworkPromptLibrary {
    /// The folder the resource files are in, in the source tree.
    static let folder = "ArtworkPrompts"

    /// The prompt's text exactly as its file has it; empty when the file
    /// is missing from the bundle.
    static func text(_ id: ArtworkPromptID, in bundle: Bundle = .main) -> String {
        let url = bundle.url(forResource: id.rawValue, withExtension: "txt")
            ?? bundle.url(forResource: id.rawValue, withExtension: "txt", subdirectory: folder)
        guard let url, let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return text
    }
}
