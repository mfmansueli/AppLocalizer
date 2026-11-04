//
//  AutopilotArtworkTextWork.swift
//  AppLocalizer
//

import Foundation

/// "2 search headlines to write, 1 header line to shorten, 26 phrases to
/// translate", for the log.
struct AutopilotArtworkTextWork {
    let needs: [AutopilotArtworkTextNeed]

    init(_ needs: [AutopilotArtworkTextNeed]) {
        self.needs = needs
    }

    var summary: String {
        var parts: [String] = []
        let missing = needs.count { $0.problem == .missing && !$0.isPhrase }
        let search = needs.count { $0.problem == .tooLong && $0.role == .search && !$0.isPhrase }
        let header = needs.count { $0.problem == .tooLong && $0.role == .header && !$0.isPhrase }
        let untranslated = needs.count { $0.problem == .missing && $0.isPhrase }
        let longPhrases = needs.count { $0.problem == .tooLong && $0.isPhrase }
        if missing > 0 { parts.append(missing == 1 ? String(localized: "1 search headline to write") : String(localized: "\(missing) search headlines to write")) }
        if search > 0 { parts.append(search == 1 ? String(localized: "1 search headline to shorten") : String(localized: "\(search) search headlines to shorten")) }
        if header > 0 { parts.append(header == 1 ? String(localized: "1 header line to shorten") : String(localized: "\(header) header lines to shorten")) }
        if untranslated > 0 {
            parts.append(untranslated == 1 ? String(localized: "1 phrase to translate") : String(localized: "\(untranslated) phrases to translate"))
        }
        if longPhrases > 0 {
            parts.append(longPhrases == 1 ? String(localized: "1 phrase to shorten") : String(localized: "\(longPhrases) phrases to shorten"))
        }
        return parts.joined(separator: ", ")
    }
}
