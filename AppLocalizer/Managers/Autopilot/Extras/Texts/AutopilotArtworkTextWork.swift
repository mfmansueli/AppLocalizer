//
//  AutopilotArtworkTextWork.swift
//  AppLocalizer
//

import Foundation

/// "2 search headlines to write, 1 header line to shorten", for the log.
struct AutopilotArtworkTextWork {
    let needs: [AutopilotArtworkTextNeed]

    init(_ needs: [AutopilotArtworkTextNeed]) {
        self.needs = needs
    }

    var summary: String {
        var parts: [String] = []
        let missing = needs.count { $0.problem == .missing }
        let search = needs.count { $0.problem == .tooLong && $0.role == .search }
        let header = needs.count { $0.problem == .tooLong && $0.role == .header }
        if missing > 0 { parts.append(missing == 1 ? String(localized: "1 search headline to write") : String(localized: "\(missing) search headlines to write")) }
        if search > 0 { parts.append(search == 1 ? String(localized: "1 search headline to shorten") : String(localized: "\(search) search headlines to shorten")) }
        if header > 0 { parts.append(header == 1 ? String(localized: "1 header line to shorten") : String(localized: "\(header) header lines to shorten")) }
        return parts.joined(separator: ", ")
    }
}
