//
//  DebugKeptScreenshots.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The DEBUG backup store: English (U.S.), German and Japanese's
/// hand-uploaded sets, kept by the Oct 12 push (drawn small on first use),
/// plus whatever scenes' pushes keep.
@MainActor
final class DebugKeptScreenshots: ScreenshotBackupStore {
    private let store = InMemoryScreenshotBackupStore()
    private let images: DebugScreenshotImages
    private let prefills: Bool
    private var isFilled = false

    init(images: DebugScreenshotImages, prefills: Bool) {
        self.images = images
        self.prefills = prefills
    }

    func keep(_ data: Data, as image: ScreenshotBackupImage, appID: String, date: Date) throws {
        fillIfNeeded()
        try store.keep(data, as: image, appID: appID, date: date)
    }

    func backup(id: String, appID: String) -> ScreenshotBackup? {
        fillIfNeeded()
        return store.backup(id: id, appID: appID)
    }

    func data(for image: ScreenshotBackupImage, appID: String) throws -> Data {
        fillIfNeeded()
        return try store.data(for: image, appID: appID)
    }

    private func fillIfNeeded() {
        guard prefills, !isFilled else { return }
        isFilled = true
        let data = ScreenshotsPushDebugData.self
        for locale in data.keptLocales {
            for display in ScreenshotsSampleData.liveDisplays {
                for slot in ScreenshotsSampleData.slotNames.indices {
                    let width = display.isTablet ? 480 : 300
                    guard let (image, size) = images.legacyImage(locale: locale, displayType: display, slot: slot, pixelWidth: width),
                          let png = ScreenshotPNG.data(image) else { continue }
                    let kept = ScreenshotBackupImage(
                        backupID: data.backupID, locale: locale, displayType: display, position: slot, liveID: "kept|\(locale)|\(display.rawValue)|\(slot)",
                        fileName: "\(locale)-\(display.shortTitle)-\(slot + 1).png", checksum: ScreenshotPNG.checksum(png), pixelSize: size,
                        origin: .uploadedByHand
                    )
                    try? store.keep(png, as: kept, appID: DebugFixtures.AppID.lumen, date: data.backupDate)
                }
            }
        }
    }
}
#endif
