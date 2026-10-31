//
//  ScreenshotsContext+Watch.swift
//  AppLocalizer
//

import Foundation

/// Apple Watch screenshots are wanted once the version's build carries a
/// watch app, whether or not the assistant reported the project.
@MainActor
extension ScreenshotsContext {
    /// Reads, with `load`, whether the version's build has an Apple Watch
    /// app. A failure leaves it false: the watch then shows only when the
    /// project's report, a plan or a live set says so.
    mutating func readWatchApp(_ load: (String) async throws -> Bool) async {
        guard let id = version.id else { return }
        hasWatchApp = await (try? load(id)) ?? false
    }
}
