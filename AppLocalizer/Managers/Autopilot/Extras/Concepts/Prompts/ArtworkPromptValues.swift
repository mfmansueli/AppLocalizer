//
//  ArtworkPromptValues.swift
//  AppLocalizer
//

import CoreText
import Foundation

/// The values a run's prompts are filled with: the app context (from the
/// brief's aboutTheApp and the project's look), what the run makes, and
/// the concept a prompt is about.
struct ArtworkPromptValues {
    let run: AutopilotRun
    let facts: ArtworkPromptFacts
    /// The app's name when its App Store page can't be read.
    let appName: String

    /// Every shared value.
    var values: [String: String] {
        let plan = run.plan
        let extras = plan.alsoMakes
        var values: [String: String] = [
            "app_name": primaryName,
            "art_direction_text_or_none": extras.artworkDirection.trimmedText.isEmpty ? "none" : "“\(extras.artworkDirection.trimmedText)”",
            "art_direction_references_or_none": references,
            "longest_app_name": longestName.name,
            "app_names_by_locale": namesByLocale,
            "subtitle": facts.profile?.subtitle ?? "",
            "categories": facts.profile?.categories.joined(separator: ", ") ?? "",
            "description_summary": AutopilotAppProfile.opening(of: facts.profile?.description ?? "", limit: 360),
            "keywords_by_locale": keywordsByLocale,
            "what_it_does": facts.look?.whatItDoes ?? Self.unknownHint,
            "screen_list_with_captions": screens,
            "audience_hint": facts.look?.audience ?? Self.unknownHint,
            "age_rating": facts.ageRating ?? "",
            "usage_moment_hint": facts.look?.usageMoment ?? Self.unknownHint,
            "app_icon_image": facts.hasIcon ? "the 1024 px icon, the last image get_design_brief attaches" : "not attached (it couldn’t be read)",
            "icon_description": facts.look?.iconDescription ?? "",
            "icon_colors": facts.profile?.iconColors.joined(separator: ", ") ?? "",
            "accent_color": facts.look?.accentColor ?? "",
            "theme_colors": facts.look?.themeColors.joined(separator: ", ") ?? "",
            "app_fonts": facts.look?.fonts.joined(separator: ", ") ?? "",
            "supports_dark": facts.look?.supportsDarkMode.map { $0 ? "yes" : "no" } ?? "",
            "design_system_summary": designSystem,
            "brand_personality": facts.look?.personality ?? Self.unknownHint,
            "brand_motifs": Self.list(facts.look?.motifs),
            "brand_avoid": Self.list(facts.look?.avoid),
            "run_locales": plan.localeCodes.joined(separator: ", "),
            "rtl_locales": rightToLeft.isEmpty ? "none" : rightToLeft.joined(separator: ", "),
            "primary_locale": plan.primaryLocale,
            "hardest_locale": hardestLocale,
            "places_sentence": placesSentence,
            "places_list": placesList,
            "kept_places_or_none": keptPlaces,
            "canvases_with_safe_areas": canvases,
            "art_show_rule": showRule,
            "art_motion": extras.makesMotion
                ? "motion loop"
                : "still only (still design a cycle, so motion can be added later)",
            "loop_seconds": String(AutopilotArtworkMotion.loopSeconds),
            "template_ids": templateIDs,
            "search_capture": searchCapture,
        ]
        if !extras.artworkSize.allowsMotion {
            values["art_motion"] = "still only (Apple takes no motion at 16:9)"
        }
        return values
    }

    /// What an unknown hint reads.
    static let unknownHint = "unknown"

    /// `“a”, “b”`, or unknown.
    static func list(_ items: [String]?) -> String {
        guard let items, !items.isEmpty else { return unknownHint }
        return items.map { "“\($0)”" }.joined(separator: ", ")
    }

    // MARK: - The app

    private var primaryName: String {
        run.appName(in: run.plan.primaryLocale, fallback: facts.profile?.name ?? appName)
    }

    /// Each run language's App Store name.
    private var names: [(locale: String, name: String)] {
        run.plan.localeCodes.map { ($0, run.appName(in: $0, fallback: facts.profile?.name ?? appName)) }
    }

    /// `en-US “Lumen: Daily Journal” · de-DE “Lumen: Tagebuch”`.
    private var namesByLocale: String {
        names.map { "\($0.locale) “\($0.name)”" }.joined(separator: " · ")
    }

    /// The name that runs widest, measured in a bold system font, which
    /// draws every script.
    var longestName: (locale: String, name: String) {
        names.max { Self.width(of: $0.name) < Self.width(of: $1.name) } ?? (run.plan.primaryLocale, primaryName)
    }

    static func width(of text: String) -> CGFloat {
        let font = CTFontCreateUIFontForLanguage(.emphasizedSystem, 100, nil)
        let string = NSAttributedString(string: text, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font as Any])
        let line = CTLineCreateWithAttributedString(string)
        return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    }

    private var keywordsByLocale: String {
        (facts.profile?.languages ?? []).filter { !$0.keywords.isEmpty }
            .map { "\($0.locale): \($0.keywords.joined(separator: ", "))" }
            .joined(separator: " · ")
    }

    /// `  1. Today: “Write one line a day”`, one line per screen.
    private var screens: String {
        run.plan.screens.enumerated().map { slot, screen in
            let caption = facts.captions[slot].flatMap { $0.isEmpty ? nil : $0 } ?? screen.caption
            return caption.isEmpty ? "  \(slot + 1). \(screen.name)" : "  \(slot + 1). \(screen.name): “\(caption)”"
        }.joined(separator: "\n")
    }

    /// "Northpier Brand in Claude Design: colors #5B4FD6, #2B2668;
    /// typefaces New York, SF Pro", or none.
    private var designSystem: String {
        guard let project = facts.designProject, project.kind.usesDesignAI else {
            if let source = facts.look?.designSource, facts.look?.hasDesignLanguage == true {
                return "no design project connected; the project's own design docs (\(source)), as below, with the icon and theme"
            }
            return "none: the app's icon and theme are its brand"
        }
        var line = "\(project.displayName) in \(project.kind.title)"
        guard let summary = project.summary else { return line }
        var parts: [String] = []
        if !summary.colors.isEmpty { parts.append("colors " + summary.colors.map { "\($0.name) \($0.hex)" }.joined(separator: ", ")) }
        if let typefaces = summary.typefaces { parts.append("typefaces \(typefaces)") }
        if let voice = summary.voice { parts.append("voice \(voice)") }
        if !parts.isEmpty { line += ": " + parts.joined(separator: "; ") }
        return line
    }

    private var references: String {
        let references = run.plan.alsoMakes.artworkDirection.references
        guard !references.isEmpty else { return "none" }
        return references.map(\.name).joined(separator: ", ") + " (get_design_brief's artworkDesign.askedByThePerson has their paths)"
    }

    private var rightToLeft: [String] {
        run.plan.localeCodes.filter { StoreLocaleCatalog.locale(code: $0)?.isRTL == true }
    }

    /// The language with the longest name, or the first right-to-left one.
    private var hardestLocale: String {
        let longest = longestName.locale
        if longest != run.plan.primaryLocale { return longest }
        return rightToLeft.first ?? longest
    }

    // MARK: - What the run makes

    /// "a 21:9 header and 3:2 search results artwork, as 20-second loops".
    var placesSentence: String {
        let extras = run.plan.alsoMakes
        let what = switch extras.artworkSize {
        case .headerAndSearch: "a 21:9 header and 3:2 search results artwork"
        case .headerOnly: "a 21:9 header"
        case .searchOnly: "3:2 search results artwork"
        case .wide: "one 16:9 image for both the header and search results"
        }
        return what + (extras.makesMotion ? ", as \(AutopilotArtworkMotion.loopSeconds)-second loops" : ", as stills")
    }

    /// "header (3840 × 1646), search (3840 × 2560)".
    private var placesList: String {
        run.plan.artworkKinds.map { "\($0.rawValue) (\($0.pixelSize.title))" }.joined(separator: ", ")
    }

    private var keptPlaces: String {
        switch run.plan.alsoMakes.artworkSize.keptKind {
        case .header: "the header (it keeps what it shows now)"
        case .search: "the search results artwork (it keeps what it shows now)"
        case .wide, nil: "none"
        }
    }

    /// One line per canvas: its size and safe area.
    private var canvases: String {
        run.plan.artworkKinds.map { kind in
            let rect = ArtworkSafeArea.rect(for: kind)
            return "  - \(kind.rawValue) \(kind.pixelSize.title): safe area x \(Int(rect.minX)), y \(Int(rect.minY)), "
                + "\(Int(rect.width)) × \(Int(rect.height)). \(ArtworkSafeArea.outsideText(for: kind))"
        }.joined(separator: "\n")
    }

    private var showRule: String {
        switch run.plan.alsoMakes.artworkShows {
        case .phone: "one real screen from the captures, in a phone (or a hand holding one)"
        case .ui: "that real screen, cropped, rounded and floating, with no device frame"
        case .scene: "the scene only: no app screens and no device"
        }
    }

    /// "night (Day to Night), land (Layered Landscape)".
    private var templateIDs: String {
        run.plan.alsoMakes.headerTemplates.map { "\($0.rawValue) (\($0.name))" }.joined(separator: ", ")
    }

    /// The capture the search page shows, or none for a scene.
    private var searchCapture: String {
        let plan = run.plan
        guard plan.alsoMakes.artworkShows.needsCaptures, plan.screens.indices.contains(plan.searchSlot) else {
            return "none: the search artwork shows no app"
        }
        let screen = plan.screens[plan.searchSlot]
        return "the picked capture of screen \(plan.searchSlot + 1), “\(screen.name)”: <img data-al=\"capture\" data-slot=\"\(plan.searchSlot + 1)\">"
    }
}
