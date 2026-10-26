//
//  ScreenshotCellKey.swift
//  AppLocalizer
//

import Foundation

/// One position in the Sets matrix: locale × display type × slot.
struct ScreenshotCellKey: Codable, Hashable, Sendable, CustomStringConvertible {
    var locale: String
    var displayType: ScreenshotDisplayType
    var slot: Int

    var description: String { "\(locale)|\(displayType.rawValue)|\(slot)" }
}
