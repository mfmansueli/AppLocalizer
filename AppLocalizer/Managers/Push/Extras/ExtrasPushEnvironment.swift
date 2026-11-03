//
//  ExtrasPushEnvironment.swift
//  AppLocalizer
//

import Foundation

/// What an extras push runs against: the asset library calls, how a made
/// file is read, the hourly budget, the clock and how long Apple's
/// processing is waited for. Tests swap every part.
struct ExtrasPushEnvironment {
    var library: any AssetLibraryPushing
    var rate: RequestRateTracker
    /// The bytes an item uploads. Videos can be large, so the file is
    /// mapped rather than copied when it can be.
    var fileData: @Sendable (URL) async throws -> Data = { try Data(contentsOf: $0, options: .mappedIfSafe) }
    var now: () -> Date = { .now }
    /// Waits while the push is paused or Apple is processing; tests return
    /// at once.
    var sleep: @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    /// The first wait between state checks while Apple processes a file;
    /// each wait doubles, up to `longestPollInterval`.
    var pollInterval: Duration = .seconds(3)
    var longestPollInterval: Duration = .seconds(30)
    /// How long processing is waited for before the item fails. Its upload
    /// is kept, so Retry Failed picks up from there.
    var processingTimeout: Duration = .seconds(900)
    /// How many 429s one request waits out before it fails.
    var rateLimitRetries = 3
}
