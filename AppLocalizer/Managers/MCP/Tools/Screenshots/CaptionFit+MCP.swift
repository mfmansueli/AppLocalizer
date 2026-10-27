//
//  CaptionFit+MCP.swift
//  AppLocalizer
//

import Foundation

extension CaptionFit {
    /// `{fits, size, lines, fill, label}`, sizes in u.
    var mcpJSON: JSONValue {
        [
            "fits": .bool(fits),
            "size": .int(Int(size.rounded())),
            "lines": .int(lines.count),
            "maxLines": .int(maxLines),
            "fill": .double((fill * 100).rounded() / 100),
            "label": .string(label),
        ]
    }

    /// Why a caption is refused: "needs 3 lines at 72 u; the template
    /// allows 2".
    var refusalText: String {
        String(localized: "needs \(lines.count) lines at \(Int(size.rounded())) u; the template allows \(maxLines)")
    }
}
