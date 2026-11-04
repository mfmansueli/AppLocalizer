//
//  AutopilotArtworkBrief.swift
//  AppLocalizer
//

import Foundation

/// What AppLocalizer asks the design source for the header and search
/// artwork: one rule a row, drawn from Apple's App Store asset guidance and
/// the plan's choices (16:9 or 21:9 and 3:2, still or a loop, what the
/// search artwork shows, the person's direction). Shown in the Design step
/// and sent with `get_design_brief`.
struct AutopilotArtworkBrief: Hashable {
    struct Row: Hashable, Identifiable {
        /// "Header · 21:9".
        var title: String
        var text: String
        var id: String { title }
    }

    var rows: [Row]

    init(_ extras: AutopilotExtras) {
        var rows: [Row] = []
        let shows = extras.artworkShows
        if extras.artworkSize == .wide {
            let focal = shows == .scene ? String(localized: "the scene’s focal point") : String(localized: "the screen")
            rows.append(Row(
                title: String(localized: "One image, two places"),
                text: String(localized: "16:9 at \(AutopilotArtworkKind.wide.pixelSize.title). The App Store crops it differently for the header and for search, so the app name, the line and \(focal) sit in the middle.")
            ))
        } else {
            rows.append(Row(
                title: String(localized: "Header · 21:9"),
                text: String(localized: """
                Brand first, for someone who has never heard of the app: the app name and one short line, \
                centered. On iPhone only the middle of the image shows, and the status bar, Back and Share \
                sit over the top, so nothing important goes on the sides or the top.
                """)
            ))
            rows.append(Row(
                title: String(localized: "Search results · 3:2"),
                text: String(localized: "Say what the app does at a glance: a headline of 2 to 5 words on one side and \(Self.showsText(shows)) on the other. The whole image shows, small, next to the app name and Get.")
            ))
        }
        rows.append(Self.safeAreaRow(extras))
        rows.append(Row(
            title: String(localized: "One look for both"),
            text: String(localized: """
            The same colors, scene and type in each, so people know the app when they go from search to \
            the product page. One clear focal point; nothing busy.
            """)
        ))
        rows.append(Row(
            title: String(localized: "About the app"),
            text: String(localized: """
            Its subtitle, categories, description, the keywords in each language and the icon’s colors, so the idea, \
            the scene and the search headline are about what this app does, not any app in its category.
            """)
        ))
        if extras.makesMotion {
            let float = switch shows {
            case .ui: String(localized: ", a slight float of the screen")
            case .phone: String(localized: ", a slight float of the phone")
            case .scene: ""
            }
            rows.append(Row(
                title: String(localized: "Motion · 20-second loop"),
                text: String(localized: "Slow, ambient movement only: light, sky, a gentle drift of the scene") + float
                    + String(localized: ". No cuts, no fast moves. The app name and the headline stay still and readable the whole time.")
            ))
            rows.append(Row(
                title: String(localized: "Poster, loop and sound"),
                text: String(localized: "The first frame is the poster and must work as a still. The last frame matches the first, so the loop has no jump. Silent: search results can’t unmute. .mov, 30 fps, \(AutopilotArtworkKind.header.pixelSize.title) and \(AutopilotArtworkKind.search.pixelSize.title).")
            ))
        } else {
            rows.append(Row(
                title: String(localized: "Still image"),
                text: extras.artworkSize == .wide
                    ? String(localized: "PNG, no transparency.")
                    : String(localized: "PNG, no transparency. \(AutopilotArtworkKind.header.pixelSize.title) and \(AutopilotArtworkKind.search.pixelSize.title).")
            ))
        }
        let direction = extras.artworkDirection
        if !direction.isEmpty {
            rows.append(Row(title: String(localized: "Your direction"), text: direction.briefLine))
        }
        rows.append(Row(
            title: String(localized: "Words"),
            text: String(localized: """
            Text in each run language, written for that language, not translated word by word. No prices, \
            awards, website addresses or other platforms. Readable at the smallest size.
            """)
        ))
        self.rows = rows
    }

    /// Where the text and the focal point go, from `ArtworkSafeArea`: the
    /// header's crop on iPhone and what sits over its top, or the 16:9
    /// image's header crop.
    static func safeAreaRow(_ extras: AutopilotExtras) -> Row {
        let what = extras.artworkShows == .scene
            ? String(localized: "the app name, every line of text and the scene’s focal point")
            : String(localized: "the app name, every line of text and the phones")
        if extras.artworkSize == .wide {
            let insets = ArtworkSafeArea.percentInsets(for: .wide)
            return Row(
                title: String(localized: "Safe area"),
                text: String(localized: "Keep \(what) inside the middle \(100 - 2 * insets.side)% of the width and below the top \(insets.top)%: the header’s crop cuts the rest. Only the background runs to the edges. Every language goes in the same space, so leave room for longer lines.")
            )
        }
        let insets = ArtworkSafeArea.percentInsets(for: .header)
        return Row(
            title: String(localized: "Safe area"),
            text: String(localized: "On the header, keep \(what) inside the middle \(100 - 2 * insets.side)% of the width and below the top \(insets.top)%; only the background runs to the edges. The search image shows whole, with rounded corners: keep text a little in from them. Every language goes in the same space, so leave room for longer lines.")
        )
    }

    /// What the search artwork shows beside its headline.
    static func showsText(_ shows: AutopilotArtworkShow) -> String {
        switch shows {
        case .phone: String(localized: "one real screen from the captures, on a phone")
        case .ui: String(localized: "one real screen from the captures, without a device frame (cropped, rounded, floating)")
        case .scene: String(localized: "a scene in the brand’s style, with no app screens and no device")
        }
    }
}
