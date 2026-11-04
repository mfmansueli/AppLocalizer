//
//  AutopilotNextStep+MCPArtworkTexts.swift
//  AppLocalizer
//

import Foundation

extension AutopilotNextStep {
    /// `write_artwork_texts`: the search results headlines (and header
    /// lines) to write or shorten, per language.
    static func writeArtworkTextsJSON(_ needs: [AutopilotArtworkTextNeed]) -> JSONValue {
        let items: [JSONValue] = needs.map { need in
            var item: [String: JSONValue] = [
                "locale": .string(need.locale),
                "placement": .string(need.role.rawValue),
                "problem": .string(need.problem.rawValue),
                "maxWords": .int(need.role.maximumWords),
            ]
            if need.role == .search { item["maxCharacters"] = .int(ArtworkTextRole.maximumSearchCharacters) }
            if !need.headline.isEmpty { item["headline"] = .string(need.headline) }
            return .object(item)
        }
        return [
            "action": "write_artwork_texts",
            "texts": .array(items),
            "how": """
            These are the header's and the search results image's own texts, not screenshot captions. search: 3–5 words \
            (at most about 32 characters) that answer what people search for, the app's purpose at a glance; start from \
            that language's keywords and subtitle (startFrom, or get_store_page) and write it in that language, like a \
            caption, naming the app's core task in its own words, never a generic line. header: \
            optional, at most about 3 words for one feeling or outcome, or an empty headline for none. No prices, \
            discounts, URLs, awards, Apple recognitions or other platforms. Send them all with propose_captions, items \
            {locale, placement, headline}, and this run's ID as run; they're saved right away and the run checks them again.
            """,
        ]
    }
}
