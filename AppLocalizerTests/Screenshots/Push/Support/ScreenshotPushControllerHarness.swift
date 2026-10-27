//
//  ScreenshotPushControllerHarness.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
@testable import AppLocalizer

/// A `ScreenshotPushController` attached to Lumen Journal's sample
/// screenshots, a fake App Store Connect and in-memory stores.
@MainActor
struct ScreenshotPushControllerHarness {
    let controller: ScreenshotPushController
    let screenshots: FakeScreenshotsServices
    let push: FakeScreenshotPushServices
    let history: PushHistory
    let clock: ScreenshotPushTestClock

    var app: StoreApp { ScreenshotPushTestFixtures.app }

    /// `controller` is the screenshot controller of a `PushController`
    /// when given; a new one otherwise.
    init(
        document: ScreenshotsDocument = ScreenshotsDebugDocuments.standard,
        context: ScreenshotsContext = ScreenshotPushTestFixtures.context(),
        history: PushHistory = PushHistory(),
        controller: ScreenshotPushController? = nil
    ) {
        screenshots = FakeScreenshotsServices(document: document, live: ScreenshotsDebugDocuments.live)
        push = FakeScreenshotPushServices(context: context)
        self.history = history
        let clock = ScreenshotPushTestClock()
        self.clock = clock
        let controller = controller ?? ScreenshotPushController(history: history, rate: RequestRateTracker(now: { clock.now }), now: { clock.now })
        controller.sleep = { _ in }
        self.controller = controller
        controller.attach(workspace(FakePushingScreenshotsServices(base: screenshots, push: push)))
    }

    /// A workspace whose Screenshots services are `screenshots`.
    func workspace(_ screenshots: any ScreenshotsServices) -> ScreenshotPushWorkspace {
        let storePage = FakeStorePageServices()
        storePage.screenshots = screenshots
        var services = WorkspaceServices.debug
        services.storePage = storePage
        let app = app
        return ScreenshotPushWorkspace(teamName: "Northpier Studio", services: services, apps: { [app] })
    }

    func load(refreshCount: Int = 0) async {
        await controller.loadPlans(selectedAppID: app.id, allApps: false, refreshCount: refreshCount)
    }

    var plan: ScreenshotPushPlan? { controller.plans[app.id] }

    /// German's hand-uploaded iPhone set, kept by the Oct 12 push.
    func keepGermanSet() throws -> ScreenshotBackup {
        let backupID = ScreenshotBackup.id(for: ScreenshotsSampleData.liveDate)
        for position in 0..<5 {
            let image = ScreenshotBackupImage(
                backupID: backupID, locale: "de-DE", displayType: .iPhone, position: position, liveID: "kept-\(position)",
                fileName: "de-\(position + 1).png", checksum: "kept\(position)", pixelSize: nil, origin: .uploadedByHand
            )
            try push.backupStore.keep(Data("kept \(position)".utf8), as: image, appID: app.id, date: ScreenshotsSampleData.liveDate)
        }
        guard let backup = push.backupStore.backup(id: backupID, appID: app.id) else { throw CocoaError(.fileNoSuchFile) }
        return backup
    }
}
#endif
