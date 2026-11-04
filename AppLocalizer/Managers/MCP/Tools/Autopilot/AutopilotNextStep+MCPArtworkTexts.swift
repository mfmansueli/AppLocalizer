//
//  AutopilotNextStep+MCPArtworkTexts.swift
//  AppLocalizer
//

import Foundation

extension AutopilotNextStep {
    /// `write_artwork_texts`: the search results headlines (and header
    /// lines) and the pages' phrases to write or shorten, per language.
    static func writeArtworkTextsJSON(_ needs: [AutopilotArtworkTextNeed]) -> JSONValue {
        let items: [JSONValue] = needs.map { need in
            if let phrase = need.phrase {
                var item: [String: JSONValue] = [
                    "locale": .string(need.locale), "placement": "text", "phrase": .string(phrase),
                    "problem": .string(need.problem.rawValue), "on": .string(need.role.rawValue),
                ]
                if !need.headline.isEmpty { item["headline"] = .string(need.headline) }
                return .object(item)
            }
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
            optional, at most about 3 words for one feeling or outcome, or an empty headline for none. text: one of the \
            phrases the header and search pages write themselves (quotes, a slogan, a list item), given in the primary \
            language as phrase: write it for that language, its meaning and tone as a native speaker would say it, not \
            word by word, about as long as the original (shorter when the problem is too_long; headline is what doesn't \
            fit). No prices, discounts, URLs, awards, Apple recognitions or other platforms. Send them all with \
            propose_captions, items {locale, placement, headline} (and phrase, exactly as given, for text), and this \
            run's ID as run; they're saved right away and the run checks them again.
            """,
        ]
    }
}
