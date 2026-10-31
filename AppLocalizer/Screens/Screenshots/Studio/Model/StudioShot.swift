//
//  StudioShot.swift
//  AppLocalizer
//

import Foundation

/// One screenshot in the preview: its slot, what draws it, and its chip.
struct StudioShot: Hashable, Sendable, Identifiable {
    var slot: Int
    /// "Today".
    var name: String
    var image: CellImageSource
    var pixelSize: PixelSize
    var chip: StudioShotChip?

    var id: Int { slot }

    /// "1 · Today".
    var label: String { "\(slot + 1) · \(name)" }

    /// Height ÷ width.
    var aspect: Double {
        pixelSize.width > 0 ? Double(pixelSize.height) / Double(pixelSize.width) : 2.17
    }
}
