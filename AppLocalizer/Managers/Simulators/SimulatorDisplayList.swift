//
//  SimulatorDisplayList.swift
//  AppLocalizer
//

import Foundation

/// A booted simulator's displays, as `xcrun simctl io <udid> enumerate`
/// lists them: each port with `Class: Display`, its UUID and default size.
/// iPhone Duo has a 1398 × 2034 cover display and a 2007 × 2853 inner one,
/// besides virtual ones; their UUIDs change each time it starts.
struct SimulatorDisplayList: Hashable, Sendable {
    struct Display: Hashable, Sendable {
        var id: String
        var size: PixelSize
    }

    var displays: [Display]

    /// Reads `enumerate`'s blocks: a `Port:` line, then indented
    /// `Key: value` lines.
    static func parse(_ text: String) -> SimulatorDisplayList {
        var displays: [Display] = []
        var id: String?
        var isDisplay = false
        var width: Int?
        var height: Int?

        func finish() {
            if isDisplay, let id, let width, let height { displays.append(Display(id: id, size: PixelSize(width: width, height: height))) }
            id = nil
            isDisplay = false
            width = nil
            height = nil
        }

        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line == "Port:" {
                finish()
                continue
            }
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon]
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            switch key {
            case "UUID": if id == nil { id = value }
            case "Class": isDisplay = value == "Display"
            case "Default width": width = Int(value)
            case "Default height": height = Int(value)
            default: break
            }
        }
        finish()
        return SimulatorDisplayList(displays: displays)
    }

    /// The display of `size`, either way round.
    func display(sized size: PixelSize) -> Display? {
        displays.first { $0.size == size || $0.size == size.rotated }
    }
}
