//
//  LanguageDownloadButton.swift
//  AppLocalizer
//

import SwiftUI
import Translation

/// "Download Languages…": asks Apple Translation to download each missing
/// language, which shows the system's own prompt, then checks again.
struct LanguageDownloadButton: View {
    let source: StoreLocale
    let targets: [StoreLocale]
    let onFinish: () async -> Void

    @State private var queue = LanguageDownloadQueue()

    var body: some View {
        let queue = queue
        Button("Download Languages…") {
            queue.start(from: source, to: targets, onFinish: onFinish)
        }
        .controlSize(.small)
        .disabled(queue.isRunning)
        .translationTask(queue.configuration) { @Sendable session in
            try? await session.prepareTranslation()
            await queue.advance()
        }
    }
}
