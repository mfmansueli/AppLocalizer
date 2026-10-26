//
//  DebugAppInformationServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `AppInformationServices` for DEBUG scenes: the sample apps' canned data
/// (`DebugAppInformationContent`), optionally failing with `error` or
/// slowed by `delay`, and the same for accessibility on its own. Never
/// contacts App Store Connect; notes and the demo password stay in memory.
///
/// `opening` puts the section in a scene's state once it has loaded: a
/// page, an open sheet or popover. It runs once per scene.
@MainActor
struct DebugAppInformationServices: AppInformationServices {
    var error: AppStoreConnectError?
    var delay: Duration?
    var accessibilitySample = DebugAppInformationContent.AccessibilitySample.lumen
    var accessibilityError: AppStoreConnectError?
    var accessibilityDelay: Duration?
    let notes: any AppInformationNotesStore
    let secrets: any SecretStore
    var opening: Opening?

    init(
        error: AppStoreConnectError? = nil,
        delay: Duration? = nil,
        accessibilitySample: DebugAppInformationContent.AccessibilitySample = .lumen,
        accessibilityError: AppStoreConnectError? = nil,
        accessibilityDelay: Duration? = nil
    ) {
        self.error = error
        self.delay = delay
        self.accessibilitySample = accessibilitySample
        self.accessibilityError = accessibilityError
        self.accessibilityDelay = accessibilityDelay
        notes = InMemoryAppInformationNotesStore([DebugFixtures.AppID.lumen: DebugAppInformationContent.notes])
        secrets = InMemorySecretStore()
    }

    func summary(for app: StoreApp) async throws -> AppInformationSummary {
        if let error { throw error }
        return DebugSummaries.appInformation(for: app.id)
    }

    func content(for app: StoreApp, versionID: String?) async throws -> AppInformationContent {
        if let delay { try await Task.sleep(for: delay) }
        if let error { throw error }
        guard app.id == DebugFixtures.AppID.lumen else {
            return DebugAppInformationContent.released(app, versionString: DebugSummaries.storePage(for: app.id).versionString ?? "1.0")
        }
        return DebugAppInformationContent.lumen(versionID: versionID)
    }

    func accessibility(for app: StoreApp) async throws -> AccessibilityContent {
        if let accessibilityDelay { try await Task.sleep(for: accessibilityDelay) }
        if let accessibilityError { throw accessibilityError }
        guard app.id == DebugFixtures.AppID.lumen else { return DebugAppInformationContent.releasedAccessibility() }
        return DebugAppInformationContent.accessibility(accessibilitySample)
    }

    /// Runs a scene's setup once, on the first view model that loads.
    @MainActor
    final class Opening {
        private var setUp: (@MainActor (AppInformationViewModel) async -> Void)?

        init(_ setUp: @escaping @MainActor (AppInformationViewModel) async -> Void) {
            self.setUp = setUp
        }

        func run(on viewModel: AppInformationViewModel) async {
            guard let setUp else { return }
            self.setUp = nil
            await setUp(viewModel)
        }
    }
}
#endif
