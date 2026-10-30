//
//  KeyAssistantStorePrompt.swift
//  AppLocalizer
//

import Foundation

/// Builds what Generate Suggestions… sends for a Store Page: the texts an
/// API key can improve without the code (subtitle, promotional text,
/// keywords and What's New) in every language with their limits, plus the
/// commits, the changelog and the reviews when the person allowed them.
enum KeyAssistantStorePrompt {
    static let fields: [ListingField] = [.subtitle, .promotionalText, .keywords, .whatsNew]

    struct Context: Sendable {
        var folder: ProjectFolderExcerpt?
        /// "~/Developer/Lumen".
        var folderPath: String?
        var reviews: [CustomerReview]?
    }

    static func plan(listing: StoreListing, context: Context) -> KeyAssistantPlan {
        let locales = listing.displayLocales
        let fields = fields.filter(listing.canEdit)
        var items: [KeyAssistantSendItem] = []
        var notes: [String] = []

        let texts = storeText(listing: listing, locales: locales, fields: fields)
        items.append(KeyAssistantSendItem(
            id: "store",
            title: String(localized: "Store Page text · \(languages(locales))"),
            tokens: KeyAssistantTokens.estimate(system) + KeyAssistantTokens.estimate(texts)
        ))
        var sections = [texts]

        if let folder = context.folder {
            let path = context.folderPath ?? ""
            if let problem = folder.problem { notes.append(problem) }
            if !folder.commits.isEmpty {
                let title = folder.tag.map { String(localized: "Commit messages since \($0)") } ?? String(localized: "Recent commit messages")
                let text = "## \(title)\n" + folder.commits.map { "- \($0)" }.joined(separator: "\n")
                sections.append(text)
                let count = folder.commits.count
                let item = folder.tag.map { tag in
                    count == 1
                        ? String(localized: "1 commit message since \(tag) · \(path)")
                        : String(localized: "\(count) commit messages since \(tag) · \(path)")
                } ?? String(localized: "\(count) recent commit messages · \(path)")
                items.append(KeyAssistantSendItem(id: "commits", title: item, tokens: KeyAssistantTokens.estimate(text)))
            }
            if let changelog = folder.changelog {
                let text = "## CHANGELOG.md, the \(changelog.title) section\n\(changelog.text)"
                sections.append(text)
                items.append(KeyAssistantSendItem(
                    id: "changelog",
                    title: String(localized: "CHANGELOG.md · the \(changelog.title) section"),
                    tokens: KeyAssistantTokens.estimate(text)
                ))
            }
        }

        if let reviews = context.reviews, !reviews.isEmpty {
            let text = "## Recent App Store reviews (to learn what people value; never quote them)\n"
                + reviews.map(\.promptLine).joined(separator: "\n")
            sections.append(text)
            items.append(KeyAssistantSendItem(
                id: "reviews",
                title: String(localized: "Last \(reviews.count) App Store reviews"),
                tokens: KeyAssistantTokens.estimate(text)
            ))
        }

        let shown = locales.prefix(2).map(\.name).joined(separator: ", ")
        return KeyAssistantPlan(
            title: locales.count > 2 ? String(localized: "Store Page · \(shown) and \(locales.count - 2) more") : String(localized: "Store Page · \(shown)"),
            items: items,
            system: system,
            user: sections.joined(separator: "\n\n"),
            notes: notes
        )
    }

    /// "English (U.S.), German, Japanese", or "12 languages".
    private static func languages(_ locales: [StoreLocale]) -> String {
        locales.count <= 3 ? locales.map(\.name).joined(separator: ", ") : String(localized: "\(locales.count) languages")
    }

    private static func storeText(listing: StoreListing, locales: [StoreLocale], fields: [ListingField]) -> String {
        var lines = ["App: \(listing.appName), version \(listing.version.versionString), being prepared for the App Store."]
        lines.append("Limits are in characters; keywords are in UTF-8 bytes, comma-separated without spaces.")
        for locale in locales {
            lines.append("")
            lines.append("## \(locale.code) · \(locale.name)\(locale == listing.primaryLocale ? " (primary language)" : "")")
            for field in fields {
                let limit = field.limit.map { " (max \($0.maximum) \($0.unit == .bytes ? "bytes" : "characters"))" } ?? ""
                let value = listing.value(field, in: locale)
                lines.append("\(field.rawValue)\(limit): \(value.isEmpty ? "(empty)" : "\"\(value)\"")")
            }
        }
        return lines.joined(separator: "\n")
    }

    static let system = """
    You suggest App Store text for an app in App Store Connect. Suggest a value only where it clearly improves a field: \
    What's New from the commits and changelog when they're given, and promotional text, subtitles and keywords that fit \
    the app and each language. Write each value in its field's language, as a native speaker would. Stay within each \
    field's limit. Keywords are comma-separated without spaces and don't repeat words already in the name or subtitle. \
    Never suggest a field's current value. Give each suggestion a one-sentence reason. Use only the field names given. \
    At most one suggestion per field and language. Answer with JSON only: \
    {"suggestions": [{"locale": "en-US", "field": "whatsNew", "value": "…", "reason": "…"}]}. \
    If nothing would improve, answer {"suggestions": []}.
    """
}
