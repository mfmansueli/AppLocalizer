//
//  ArtworkPrompt.swift
//  AppLocalizer
//

import CryptoKit
import Foundation

/// One filled prompt, as next_step hands it to the design AI.
struct ArtworkPrompt: Hashable, Sendable {
    var id: ArtworkPromptID
    var text: String
    /// What the prompt is about: a concept's id, the note's targets.
    var about: String?

    /// The version every prompt has.
    var version: String { ArtworkPromptID.version }

    /// The text's SHA-256, for the log.
    var hash: String { Self.hash(text) }

    static func hash(_ text: String) -> String {
        hash(Data(text.utf8))
    }

    static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    /// `next_step`'s prompt object.
    var mcpJSON: JSONValue {
        var json: [String: JSONValue] = ["id": .string(id.rawValue), "version": .string(version), "text": .string(text)]
        if let about { json["for"] = .string(about) }
        return .object(json)
    }
}
