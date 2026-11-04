//
//  StudioArtworkDetails.swift
//  AppLocalizer
//

import Foundation

/// Under the App Store preview, the new set's header and search artwork in
/// the shown language: each image's size and format, its text, what its
/// checks found, and whether it's new, on App Store Connect or discarded;
/// then the same across every language.
struct StudioArtworkDetails: Hashable {
    /// How a line reads: plain, the accent (new), or a check's color.
    enum Tone: Hashable {
        case neutral
        case accent
        case positive
        case warning
        case danger
    }

    struct Row: Hashable, Identifiable {
        /// The extra's ID: `header-de-DE`.
        var id: String
        var kind: AutopilotArtworkKind
        /// "Header · 21:9".
        var title: String
        /// "3840 × 1646 · PNG · 6.4 MB".
        var format: String
        /// "“Calm mornings”", "No line: the app name only".
        var text: String
        var checks: String
        var checksTone: Tone
        var status: String
        var statusTone: Tone
        /// Made in this language: View Larger opens it.
        var isMade = true

        /// Where View Larger opens: the header (or the 16:9 image) first,
        /// then search.
        var viewerIndex: Int { kind == .search ? 1 : 0 }
    }

    /// "German".
    var languageName: String
    var rows: [Row]
    /// "15 languages · 3 on App Store Connect · 1 with warnings · 1 can’t
    /// be pushed".
    var languagesSummary: String

    static let shownOn = String(localized: "Shown on iOS 27 and iPadOS 27 and later; earlier versions show the screenshots.")

    /// Nil without artwork. `hasLocalization` says whether App Store
    /// Connect has the version's localization for a language.
    init?(extras: ScreenshotExtras, locale: String, hasLocalization: (String) -> Bool) {
        guard let size = extras.artworkSize, extras.hasArtwork else { return nil }
        let name = StoreLocaleCatalog.locale(code: locale)?.name ?? locale
        languageName = name
        rows = size.kinds.map { kind in
            guard let file = extras.artwork(kind, locale: locale) else { return Self.missingRow(kind, locale: locale, languageName: name) }
            return Self.row(file, extras: extras, languageName: name, hasLocalization: hasLocalization(locale))
        }
        languagesSummary = Self.languagesSummary(extras)
    }

    // MARK: - Rows

    private static func row(_ file: ExtrasArtworkFile, extras: ScreenshotExtras, languageName: String, hasLocalization: Bool) -> Row {
        let (checks, checksTone) = checksLine(file)
        let (status, statusTone) = statusLine(file, extras: extras, languageName: languageName, hasLocalization: hasLocalization)
        return Row(
            id: file.id, kind: file.kind, title: title(file.kind), format: format(file), text: text(file),
            checks: checks, checksTone: checksTone, status: status, statusTone: statusTone
        )
    }

    private static func missingRow(_ kind: AutopilotArtworkKind, locale: String, languageName: String) -> Row {
        Row(
            id: "\(kind.rawValue)-\(locale)", kind: kind, title: title(kind), format: kind.pixelSize.title, text: "—",
            checks: "—", checksTone: .neutral,
            status: String(localized: "Not made in \(languageName): App Store Connect keeps what it has"), statusTone: .neutral,
            isMade: false
        )
    }

    /// "Header · 21:9", "Header and search · 16:9".
    static func title(_ kind: AutopilotArtworkKind) -> String {
        "\(kind.title) · \(kind.ratioTitle)"
    }

    /// "3840 × 1646 · PNG · 6.4 MB", "3840 × 1646 · 0:20 loop · 30 fps ·
    /// H.264 · seamless · 18 MB".
    static func format(_ file: ExtrasArtworkFile) -> String {
        guard let loop = file.loop else {
            return [file.pixelSize.title, "PNG", bytes(file.byteCount)].joined(separator: " · ")
        }
        return [
            file.pixelSize.title, loop.chipTitle, String(localized: "\(loop.framesPerSecond) fps"), loop.codec,
            loop.isSeamless ? String(localized: "seamless") : String(localized: "jumps where it loops"), bytes(loop.byteCount),
        ].joined(separator: " · ")
    }

    /// The line it carries, or for a header without one, the name alone.
    static func text(_ file: ExtrasArtworkFile) -> String {
        let headline = file.headline.trimmingCharacters(in: .whitespacesAndNewlines)
        let line = switch (headline.isEmpty, file.kind) {
        case (true, .header): String(localized: "No line: the app name only")
        case (true, _): String(localized: "No headline yet")
        case (false, _): "“\(headline)”"
        }
        return file.fits ? line : line + " · " + String(localized: "too long even at its smallest size")
    }

    /// Errors first (they keep it out of the push), then warnings.
    static func checksLine(_ file: ExtrasArtworkFile) -> (String, Tone) {
        guard let checks = file.checks else { return (String(localized: "Not checked: made before the checks"), .neutral) }
        let errors = file.errors
        let warnings = file.warnings
        if let first = errors.first {
            let more = checks.count - 1
            let rest = more > 0 ? " · " + String(localized: "\(more) more") : ""
            return (String(localized: "Can’t be pushed: \(first.text)") + rest, .danger)
        }
        if let first = warnings.first {
            let lead = warnings.count == 1 ? String(localized: "1 warning") : String(localized: "\(warnings.count) warnings")
            return ("\(lead): \(first.text)", .warning)
        }
        return (String(localized: "Passed every check"), .positive)
    }

    /// On App Store Connect, discarded, or new and what happens to it.
    static func statusLine(_ file: ExtrasArtworkFile, extras: ScreenshotExtras, languageName: String, hasLocalization: Bool) -> (String, Tone) {
        let pushed = extras.pushedChecksums?[file.id]
        if pushed == file.fileID { return (String(localized: "On App Store Connect"), .positive) }
        if extras.discardedChecksums?[file.id] == file.fileID {
            return (String(localized: "Discarded: App Store Connect keeps what it has"), .neutral)
        }
        if !file.errors.isEmpty { return (String(localized: "New · stays out of the push until it’s fixed"), .danger) }
        if !hasLocalization {
            return (String(localized: "New · App Store Connect has no \(languageName) localization on this version yet"), .warning)
        }
        if pushed != nil { return (String(localized: "New · replaces the one on App Store Connect"), .accent) }
        return (String(localized: "New · waits in Review & Push"), .accent)
    }

    // MARK: - Every language

    /// "15 languages · 3 on App Store Connect · 1 with warnings · 1 can’t
    /// be pushed".
    static func languagesSummary(_ extras: ScreenshotExtras) -> String {
        let byLocale = Dictionary(grouping: extras.artwork, by: \.locale)
        let pushed = extras.pushedChecksums ?? [:]
        let onStore = byLocale.values.count { files in files.allSatisfy { pushed[$0.id] == $0.fileID } }
        let blocked = byLocale.values.count { files in files.contains { !$0.errors.isEmpty } }
        let warned = byLocale.values.count { files in files.allSatisfy(\.errors.isEmpty) && files.contains { !$0.warnings.isEmpty } }
        var parts = [byLocale.count == 1 ? String(localized: "1 language") : String(localized: "\(byLocale.count) languages")]
        if onStore > 0 { parts.append(String(localized: "\(onStore) on App Store Connect")) }
        if warned > 0 { parts.append(String(localized: "\(warned) with warnings")) }
        if blocked > 0 { parts.append(blocked == 1 ? String(localized: "1 can’t be pushed") : String(localized: "\(blocked) can’t be pushed")) }
        return parts.joined(separator: " · ")
    }

    private static func bytes(_ count: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }
}
