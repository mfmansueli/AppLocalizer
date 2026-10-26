//
//  AppInformationAPIValue.swift
//  AppLocalizer
//

import Foundation

/// One attribute value in an App Information write: a string (an enum like
/// `INFREQUENT`, or text), a boolean (`supportsVoiceover`), or `null`, which
/// clears the attribute.
enum AppInformationAPIValue: Codable, Hashable, Sendable {
    case string(String)
    case bool(Bool)
    case null

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else {
            self = try .string(container.decode(String.self))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(text): try container.encode(text)
        case let .bool(flag): try container.encode(flag)
        case .null: try container.encodeNil()
        }
    }

    /// Text, or `null` when it's empty.
    static func text(_ text: String) -> AppInformationAPIValue {
        text.isEmpty ? .null : .string(text)
    }

    var stringValue: String? {
        if case let .string(text) = self { return text }
        return nil
    }

    var boolValue: Bool? {
        if case let .bool(flag) = self { return flag }
        return nil
    }

    /// What a `ConflictCheck` reads back for this value: booleans as `1` and
    /// `0` (JSON numbers), `null` as nil.
    var conflictValue: String? {
        switch self {
        case let .string(text): text.isEmpty ? nil : text
        case let .bool(flag): flag ? "1" : "0"
        case .null: nil
        }
    }
}
