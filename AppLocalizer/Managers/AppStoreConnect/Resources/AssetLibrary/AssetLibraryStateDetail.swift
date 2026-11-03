//
//  AssetLibraryStateDetail.swift
//  AppLocalizer
//

import Foundation

/// One of Apple's `stateDetails` on an asset or placement: a validation
/// error, warning or note, e.g. `IMAGE_INCORRECT_DIMENSIONS`.
struct AssetLibraryStateDetail: Decodable, Hashable, Sendable {
    var code: String?
    /// Apple's `description`.
    var message: String?

    private enum CodingKeys: String, CodingKey {
        case code
        case message = "description"
    }

    init(code: String?, message: String?) {
        self.code = code
        self.message = message
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try? container.decodeIfPresent(String.self, forKey: .code)
        message = try? container.decodeIfPresent(String.self, forKey: .message)
    }

    /// "IMAGE_INCORRECT_DIMENSIONS — The image is 3000 × 1286", or just
    /// one of the two.
    var text: String? {
        let parts = [code, message].compactMap { $0?.isEmpty == false ? $0 : nil }
        return parts.isEmpty ? nil : parts.joined(separator: " — ")
    }

    /// Reads `stateDetails` leniently: the documented list, or a list per
    /// kind (`errors`, `warnings`, `infos`). Anything else is no details.
    static func list<Key: CodingKey>(in container: KeyedDecodingContainer<Key>, forKey key: Key) -> [AssetLibraryStateDetail] {
        if let list = try? container.decodeIfPresent([AssetLibraryStateDetail].self, forKey: key) { return list }
        if let grouped = try? container.decodeIfPresent(Grouped.self, forKey: key) { return grouped.all }
        return []
    }

    private struct Grouped: Decodable {
        var errors: [AssetLibraryStateDetail]?
        var warnings: [AssetLibraryStateDetail]?
        var infos: [AssetLibraryStateDetail]?

        var all: [AssetLibraryStateDetail] { (errors ?? []) + (warnings ?? []) + (infos ?? []) }
    }
}
