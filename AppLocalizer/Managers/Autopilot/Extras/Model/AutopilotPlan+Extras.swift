//
//  AutopilotPlan+Extras.swift
//  AppLocalizer
//

import Foundation

/// What "Also make" adds to a plan: the artwork made per language, and the
/// App Previews and the recordings they're made from.
extension AutopilotPlan {
    /// The person's choices; both off in runs from before.
    var alsoMakes: AutopilotExtras {
        get { extras ?? AutopilotExtras() }
        set { extras = newValue }
    }

    /// The slots a kind's phone shows: none on the header (it never shows
    /// a device), the search screen in search results and on the one 16:9
    /// image, none when the artwork is a scene.
    func artworkSlots(for kind: AutopilotArtworkKind) -> [Int] {
        guard kind != .header, alsoMakes.artworkShows.needsCaptures, !screens.isEmpty else { return [] }
        return [searchSlot]
    }

    /// The artwork made in each language; none when it's off.
    var artworkKinds: [AutopilotArtworkKind] {
        alsoMakes.makesArtwork ? alsoMakes.artworkSize.kinds : []
    }

    /// The devices that get an App Preview: the App Preview row's (iPhone
    /// and iPad), else the screenshots' when they plan them.
    var previewDisplays: [ScreenshotDisplayType] {
        guard alsoMakes.makesAppPreview else { return [] }
        let chosen = runChoice.previewDisplays ?? displayTypes
        return AutopilotExtras.previewDisplays.filter(chosen.contains)
    }

    /// The languages with an App Preview of their own: every one, or the
    /// primary only (the App Store shows it in the others).
    var previewLocales: [String] {
        alsoMakes.previewLanguages == .all ? localeCodes : [primaryLocale]
    }

    /// The languages recorded: each one with its own App Preview when the
    /// app is captured in each language, else the primary only.
    var recordedLocales: [String] {
        capturesEachLanguage ? previewLocales : [primaryLocale]
    }

    /// Every recording to make: each device in each recorded language.
    var recordingTargets: [AutopilotRecordingTarget] {
        previewDisplays.flatMap { display in
            recordedLocales.map { AutopilotRecordingTarget(displayType: display, locale: $0) }
        }
    }

    /// The slot whose caption the search results artwork carries: the
    /// screen named for search, else the first.
    var searchSlot: Int {
        screens.firstIndex { screen in
            [screen.id, screen.name].contains { $0.range(of: "search", options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        } ?? 0
    }

    /// "header and search artwork and an App Preview in every language";
    /// nil when neither is on.
    var extrasTitle: String? {
        var parts: [String] = []
        if alsoMakes.makesArtwork { parts.append(artworkMadeTitle) }
        if !previewDisplays.isEmpty {
            if alsoMakes.previewLanguages == .all {
                parts.append(String(localized: "an App Preview in every language"))
            } else {
                let name = StoreLocaleCatalog.locale(code: primaryLocale)?.name ?? primaryLocale
                parts.append(String(localized: "an App Preview in \(name)"))
            }
        }
        return parts.isEmpty ? nil : parts.formatted(.list(type: .and))
    }

    /// "header and search artwork", "moving header artwork", "one 16:9
    /// header and search image".
    var artworkMadeTitle: String {
        alsoMakes.makesMotion ? alsoMakes.artworkSize.movingTitle : alsoMakes.artworkSize.madeTitle
    }

    /// Design's log: "Brief also asks for a 21:9 header (3840 × 1646) and
    /// 3:2 search artwork (3840 × 2560) in each direction", and the App
    /// Preview's captions, end card and poster frame.
    var briefExtrasLines: [String] {
        var lines: [String] = []
        if alsoMakes.makesArtwork {
            let what = alsoMakes.artworkSize.briefTitle
            lines.append(alsoMakes.makesMotion
                ? String(localized: "Brief also asks for \(what), each as a 20-second loop with a still poster frame in each direction")
                : String(localized: "Brief also asks for \(what) in each direction"))
        }
        if !previewDisplays.isEmpty {
            lines.append(String(localized: "Brief also asks for App Preview captions, an end card and a poster frame from the recordings"))
        }
        return lines
    }
}
