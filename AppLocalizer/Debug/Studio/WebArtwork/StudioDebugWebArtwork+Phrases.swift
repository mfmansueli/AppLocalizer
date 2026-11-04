//
//  StudioDebugWebArtwork+Phrases.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Quiet Indigo with a phrase of its own on the search page, written once
/// in English as Claude Design writes them now, and read by Localize: what
/// `cap-artwork-phrases` shows as a Captions column.
extension StudioDebugWebArtwork {
    static let phrase = "Small steps count."

    static var withPhrase: AutopilotArtworkDesign {
        var design = quietIndigo
        let element = """
        <p data-al="text" data-al-fit style="position: absolute; inset-inline-start: 300px; top: 1950px; width: 1700px; \
        height: 180px; margin: 0; font: italic 600 100px/1.1 ui-serif; color: #fbf7ff">\(phrase)</p>
        """
        design.setPage(design.page(for: .search)?.replacingOccurrences(of: "</body>", with: element + "</body>"), for: .search)
        design.setPhrases([], for: .header)
        design.setPhrases([phrase], for: .search)
        return design
    }
}
#endif
