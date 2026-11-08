//
//  AutopilotAppProfile+MCP.swift
//  AppLocalizer
//

import Foundation

extension AutopilotAppProfile {
    /// Loads the app's listing, categories and icon colors for the plan's
    /// `locales`; nil when the listing can't be read (the brief goes on
    /// without it).
    static func load(app: StoreApp, locales: [String], in workspace: MCPWorkspace) async -> AutopilotAppProfile? {
        guard let listing = try? await MCPListingDraft.load(app: app.id, in: workspace).listing else { return nil }
        let general = try? await MCPAppInformationDraft.load(app: app.id, in: workspace, includesAccessibility: false).general
        let categories = [general?.primaryCategory, general?.secondaryCategory].compactMap { id in
            id.flatMap { id in AppCategory.all.first { $0.id == id }?.name }
        }
        let palette = await IconPalette.palette(for: app.icon)
        return AutopilotAppProfile(listing: listing, locales: locales, categories: categories, palette: palette)
    }

    /// `get_design_brief`'s `aboutTheApp`.
    var mcpJSON: JSONValue {
        var json: [String: JSONValue] = [
            "name": .string(name),
            "useIt": .string(Self.useIt),
            "languages": .array(languages.map(\.mcpJSON)),
        ]
        if !subtitle.isEmpty { json["subtitle"] = .string(subtitle) }
        if !categories.isEmpty { json["categories"] = .array(categories.map(JSONValue.string)) }
        if !promotionalText.isEmpty { json["promotionalText"] = .string(promotionalText) }
        if !description.isEmpty { json["description"] = .string(description) }
        if !iconColors.isEmpty { json["iconColors"] = .array(iconColors.map(JSONValue.string)) }
        return .object(json)
    }

    /// `write_artwork_texts`' words to start from, for the languages it asks.
    func searchWordsJSON(for locales: [String]) -> JSONValue {
        .array(languages.filter { locales.contains($0.locale) }.map(\.mcpJSON))
    }

    /// How the design AI uses the profile.
    static let useIt = """
    Design for this app, not for any app in its categories. Read the subtitle, promotional text and description for \
    what it does, for whom and the moment people use it, and look (from the project) for its personality, motifs and \
    what the brand avoids, then: give each direction an idea that comes from the app's own world (its name, icon, \
    look.motifs, the job its screens show) and the feel of look.personality; never use what look.avoid lists, nor the \
    category's clichés, unless the person asks for them; start the colors from iconColors, look's accent and theme \
    colors and the design project, and the type from look.fonts; \
    write the search headline from that language's keywords and subtitle, naming the core task in the app's own \
    words (what people type to find it); keep the header's line, when there is one, to the feeling or outcome the \
    description promises; for the search image, show the capture where that task happens. Use only what these texts \
    and the captures show: no features, numbers, ratings or claims they don't make, and no generic lines like "your \
    daily companion" or "all in one". In each direction's rationale, say what about the app it draws on.
    """
}

extension AutopilotAppProfile.Language {
    var mcpJSON: JSONValue {
        var json: [String: JSONValue] = ["locale": .string(locale), "keywords": .array(keywords.map(JSONValue.string))]
        if !name.isEmpty { json["name"] = .string(name) }
        if !subtitle.isEmpty { json["subtitle"] = .string(subtitle) }
        return .object(json)
    }
}
