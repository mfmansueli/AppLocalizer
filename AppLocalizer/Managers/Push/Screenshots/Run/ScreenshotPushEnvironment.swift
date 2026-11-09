//
//  ScreenshotPushEnvironment.swift
//  AppLocalizer
//

import Foundation

/// What a screenshot push runs against: the transport, where replaced
/// screenshots are kept, how an image's PNG is made, the hourly budget and
/// the clock. Tests swap every part.
struct ScreenshotPushEnvironment {
    var transport: any ScreenshotUploadTransport
    var backups: any ScreenshotBackupStore
    /// The PNG an image uploads: a render at full size, or a kept file.
    var imageData: @MainActor (ScreenshotPlanItem) async throws -> Data
    /// A live screenshot's file, kept before the push deletes it.
    var liveData: @MainActor (LiveScreenshot) async throws -> Data
    var rate: RequestRateTracker
    var now: () -> Date = { .now }
    /// Waits while the push is paused; tests return at once.
    var sleep: @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    /// Sets uploaded at the same time; each set's images go one by one.
    var concurrentSets = 3
    /// How many times, and how far apart, a finished set's new images are
    /// checked before what they replace is deleted.
    var deliveryChecks = 20
    var deliveryInterval: Duration = .seconds(3)
}
