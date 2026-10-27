//
//  ScreenshotBackupImage.swift
//  AppLocalizer
//

import Foundation

/// One live screenshot a push replaced, kept on this Mac before it was
/// deleted: where it was (locale, display type, position in the set),
/// what App Store Connect called it, and how it had been made.
struct ScreenshotBackupImage: Codable, Hashable, Sendable, Identifiable {
    /// The backup (one push) it belongs to.
    var backupID: String
    var locale: String
    var displayType: ScreenshotDisplayType
    /// Its position in the set when it was replaced, from 0.
    var position: Int
    /// The `appScreenshots` ID it had.
    var liveID: String
    var fileName: String
    var checksum: String?
    var pixelSize: PixelSize?
    var origin: ScreenshotBackupOrigin

    var id: String { "\(backupID)|\(locale)|\(displayType.rawValue)|\(position)" }

    /// The slot a restore puts it back in.
    var cell: ScreenshotCellKey {
        ScreenshotCellKey(locale: locale, displayType: displayType, slot: position)
    }

    /// Where the file is inside the backup's folder:
    /// `de-DE/APP_IPHONE_67/3.png`.
    var relativePath: String {
        "\(locale)/\(displayType.rawValue)/\(position + 1).png"
    }
}
