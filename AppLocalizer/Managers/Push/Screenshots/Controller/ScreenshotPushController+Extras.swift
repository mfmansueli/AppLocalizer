//
//  ScreenshotPushController+Extras.swift
//  AppLocalizer
//

import Foundation

/// Autopilot's extras in Review & Push: planned with the screenshots from
/// the same document, pushed through the App Asset Library on their own
/// run, and recorded in the document once App Store Connect has them.
extension ScreenshotPushController {
    /// Nil when these services can't send extras.
    var extrasProvider: (any ExtrasPushProviding)? {
        workspace?.pushing as? any ExtrasPushProviding
    }

    var canPushExtras: Bool { extrasProvider != nil }

    /// Plans `app`'s extras from its saved document.
    func planExtras(for app: StoreApp, document: ScreenshotsDocument, context: ScreenshotsContext) {
        guard let screenshots = workspace?.screenshots else { return }
        let planner = ExtrasReviewPlanner { id, pathExtension in
            screenshots.extrasFileURL(id, pathExtension: pathExtension, for: app)
        }
        extras.setPlan(planner.plan(appID: app.id, appName: app.name, extras: document.extras, context: context), for: app.id)
    }

    /// Discard: each item leaves review and stays off App Store Connect
    /// until Undo, or until it's made again (another file).
    func discardExtras(_ items: [ExtrasReviewItem]) async {
        extras.unchecked.subtract(items.map(\.id))
        for (appID, appItems) in Dictionary(grouping: items, by: \.appID) {
            await changeDiscards(appID: appID) { discarded in
                for item in appItems {
                    discarded[item.id] = item.fileID
                }
            }
        }
    }

    /// Undo: every extra discarded in `appIDs` goes back to review.
    func undoExtrasDiscards(appIDs: [StoreApp.ID]) async {
        for appID in appIDs where extras.plans[appID]?.discardedCount ?? 0 > 0 {
            await changeDiscards(appID: appID) { $0 = [:] }
        }
    }

    /// Saves `change` to the app's discarded extras and plans them again.
    private func changeDiscards(appID: StoreApp.ID, _ change: (inout [String: String]) -> Void) async {
        guard let workspace, let app = apps[appID], let context = contexts[appID] else { return }
        do {
            var document = try await workspace.screenshots.loadDocument(for: app, primaryLocale: context.primaryLocale)
            guard var made = document.extras else { return }
            var discarded = made.discardedChecksums ?? [:]
            change(&discarded)
            made.discardedChecksums = discarded.isEmpty ? nil : discarded
            document.extras = made
            try await workspace.screenshots.saveDocument(document, for: app)
            planExtras(for: app, document: document, context: context)
            bumpRevision(for: appID)
        } catch {
            extras.recordError = String(localized: "Couldn’t change \(app.name)’s extras: \(error.localizedDescription)")
        }
    }

    /// Pushes the checked extras of `plans` without errors.
    func pushExtras(_ plans: [ExtrasReviewPlan]) {
        guard let provider = extrasProvider, !extras.isPushing else { return }
        let items = plans.flatMap { extras.checkedItems(in: $0) }.compactMap(\.pushItem)
        guard !items.isEmpty else { return }
        let environment = ExtrasPushEnvironment(library: provider.assetLibrary, rate: rate, now: now, sleep: sleep)
        let run = ExtrasPushRun(items: items, environment: environment)
        run.onFinish = { [weak self] run in await self?.recordExtras(run) }
        run.onItemDone = { [weak self] item in await self?.recordPushedExtra(item) }
        extras.run = run
        run.start()
    }

    /// The App Asset Library sheet's model for the app, when the services
    /// can reach its library.
    func assetLibraryModel(appID: StoreApp.ID) -> AssetLibraryModel? {
        guard let provider = extrasProvider else { return nil }
        return AssetLibraryModel(appID: appID, appName: apps[appID]?.name ?? "", manager: provider.assetLibraryFiles)
    }

    /// The Product Page Optimization sheet's model for `placement` of
    /// `plan`'s artwork. Both variants are exported to the app's Extras
    /// folder when the API can't make the test.
    func testModel(for plan: ExtrasReviewPlan, placement: ProductPageTestPlacement) -> ProductPageTestModel? {
        guard let workspace, let app = apps[plan.appID] else { return nil }
        let screenshots = workspace.screenshots
        let environment = extrasProvider.map { provider in
            ProductPageTestEnvironment(
                tester: provider.productPageTesting, library: provider.assetLibrary, rate: rate, now: now, sleep: sleep
            )
        }
        let stamp = now().formatted(.iso8601.year().month().day().dateSeparator(.dash))
        let folder = screenshots.extrasFolder(for: app).appending(path: "Product Page Tests").appending(path: "\(placement.title) \(stamp)")
        let primary = contexts[plan.appID]?.primaryLocale ?? StoreLocaleCatalog.locale(code: plan.primaryLocale)
        return ProductPageTestModel(
            plan: plan, placement: placement, environment: environment,
            fileURL: { id, pathExtension in screenshots.extrasFileURL(id, pathExtension: pathExtension, for: app) },
            exportFolder: folder,
            loadExtras: {
                guard let primary else { return nil }
                return try? await screenshots.loadDocument(for: app, primaryLocale: primary).extras
            }
        )
    }

    /// Writes what App Store Connect now has into each app's document, so
    /// the pushed extras leave Review & Push.
    /// Notes one extra in its app's set as soon as it's placed, so a push
    /// cut short (the app quit) doesn't send it again. Review & Push's
    /// plans change once the push ends (`recordExtras`).
    func recordPushedExtra(_ item: ExtrasPushItem) async {
        guard let workspace, let app = apps[item.appID], let context = contexts[item.appID] else { return }
        do {
            var document = try await workspace.screenshots.loadDocument(for: app, primaryLocale: context.primaryLocale)
            guard document.extras != nil else { return }
            var pushed = document.extras?.pushedChecksums ?? [:]
            pushed[item.id] = extras.fileID(of: item)
            document.extras?.pushedChecksums = pushed
            try await workspace.screenshots.saveDocument(document, for: app)
        } catch {
            extras.recordError = String(localized: "Pushed, but couldn’t note it in \(app.name)’s set: \(error.localizedDescription)")
        }
    }

    func recordExtras(_ run: ExtrasPushRun) async {
        guard let workspace else { return }
        var changed: Set<StoreApp.ID> = []
        for appID in Set(run.items.map(\.appID)) {
            let done = run.items.filter { $0.appID == appID && run.status(of: $0).isDone }
            guard !done.isEmpty, let app = apps[appID], let context = contexts[appID] else { continue }
            do {
                var document = try await workspace.screenshots.loadDocument(for: app, primaryLocale: context.primaryLocale)
                guard document.extras != nil else { continue }
                var pushed = document.extras?.pushedChecksums ?? [:]
                for item in done {
                    pushed[item.id] = extras.fileID(of: item)
                }
                document.extras?.pushedChecksums = pushed
                try await workspace.screenshots.saveDocument(document, for: app)
                planExtras(for: app, document: document, context: context)
                bumpRevision(for: appID)
                changed.insert(appID)
            } catch {
                extras.recordError = String(localized: "Pushed, but couldn’t note it in \(app.name)’s set: \(error.localizedDescription)")
            }
        }
        if !changed.isEmpty { onPushed(changed) }
    }
}
