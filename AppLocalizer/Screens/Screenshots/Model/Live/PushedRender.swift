//
//  PushedRender.swift
//  AppLocalizer
//

import Foundation

/// A render AppLocalizer uploaded: its render key and the MD5 of the PNG.
/// A cell is Live when the live screenshot in its position has this
/// checksum and the render key is still the current one.
struct PushedRender: Codable, Hashable, Sendable {
    var cell: ScreenshotCellKey
    var renderKey: RenderKey
    var checksum: String
    var date: Date
}
