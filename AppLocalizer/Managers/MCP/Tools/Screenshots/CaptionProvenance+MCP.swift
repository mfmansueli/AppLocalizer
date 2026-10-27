//
//  CaptionProvenance+MCP.swift
//  AppLocalizer
//

import Foundation

extension CaptionProvenance {
    /// `get_captions`' state: written, edited, reviewed, machine-translated
    /// or proposed.
    var mcpState: String {
        switch self {
        case .written: "written"
        case .edited: "edited"
        case .reviewed: "reviewed"
        case .machineTranslated: "machine-translated"
        case .assistant: "proposed"
        }
    }
}
