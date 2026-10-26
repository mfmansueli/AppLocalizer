//
//  LanguageDownloadQueue.swift
//  AppLocalizer
//

import Foundation
import Observation
import Translation

/// The languages "Download Languages…" still has to ask Apple Translation
/// for, one at a time: each becomes a `TranslationSession.Configuration`
/// that `.translationTask` turns into the system's download prompt.
@MainActor
@Observable
final class LanguageDownloadQueue {
    private(set) var configuration: TranslationSession.Configuration?
    private var source: StoreLocale?
    private var remaining: [StoreLocale] = []
    private var onFinish: (() async -> Void)?

    var isRunning: Bool { configuration != nil }

    func start(from source: StoreLocale, to targets: [StoreLocale], onFinish: @escaping () async -> Void) {
        self.source = source
        remaining = targets
        self.onFinish = onFinish
        advance()
    }

    /// The current language is done (downloaded or declined): ask for the
    /// next, or report back when there's none left.
    func advance() {
        guard let source, !remaining.isEmpty else {
            configuration = nil
            let onFinish = onFinish
            self.onFinish = nil
            Task { await onFinish?() }
            return
        }
        let target = remaining.removeFirst()
        configuration = TranslationSession.Configuration(source: source.language, target: target.language)
    }
}
