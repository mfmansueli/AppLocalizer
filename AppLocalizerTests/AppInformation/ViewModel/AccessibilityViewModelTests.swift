//
//  AccessibilityViewModelTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Accessibility page's view model on Lumen's sample: the editor,
/// Copy from iPhone, Delete Draft, the publish switch and the URL.
@MainActor
@Suite("AppInformationViewModel · Accessibility")
struct AccessibilityViewModelTests {
    private let queue = ChangeQueue()
    private let app = StoreApp(id: DebugFixtures.AppID.lumen, name: "Lumen Journal", bundleID: "dev.example.lumen", sku: nil, primaryLocale: "en-US")

    private func loaded(_ services: DebugAppInformationServices = DebugAppInformationServices()) async -> AppInformationViewModel {
        let viewModel = AppInformationViewModel(app: app, services: services, queue: queue)
        await viewModel.load()
        return viewModel
    }

    @Test func cardsFollowTheSample() async {
        let vm = await loaded()
        #expect(vm.accessibilityCards.map(\.family) == [.iPhone, .iPad, .appleWatch, .vision])
        #expect(vm.accessibilityCards.map(\.state) == [.published, .draft, .notDeclared, .draftCantPublish])
        #expect(!vm.isNeverDeclared)
        #expect(vm.otherFamilies.isEmpty)
        #expect(await loaded(DebugAppInformationServices(accessibilitySample: .neverDeclared)).isNeverDeclared)
    }

    @Test func savingTheEditorQueuesTheDeclarationWithThePublishSwitch() async throws {
        let vm = await loaded()
        vm.openEditor(.iPhone)
        #expect(vm.editor?.supportsAny == true)
        vm.editor?.toggle(.reducedMotion)
        vm.saveEditor()
        #expect(vm.editor == nil)
        #expect(vm.toast == "Saved. It’s waiting in Review & Push, where you choose whether to publish it.")
        let change = try #require(queue.change(id: vm.builder.accessibilityChangeID(.iPhone)))
        #expect(change.option?.isOn == true)
        #expect(vm.card(for: .iPhone)?.state == .publishedChangesWaiting)
        #expect(vm.card(for: .iPhone)?.unpublishedFeatures == [.reducedMotion])
    }

    @Test func editingAgainKeepsTheSwitchYouFlippedInReview() async {
        let vm = await loaded()
        vm.openEditor(.iPad)
        vm.editor?.toggle(.captions)
        vm.saveEditor()
        let id = vm.builder.accessibilityChangeID(.iPad)
        queue.setOption(id: id, isOn: false)
        vm.openEditor(.iPad)
        vm.editor?.toggle(.audioDescriptions)
        vm.saveEditor()
        #expect(queue.change(id: id)?.option?.isOn == false)
    }

    @Test func copyFromIPhoneToTheWatchLeavesOutVoiceControlAndSaysSo() async throws {
        let vm = await loaded()
        vm.copyFromIPhone(to: .appleWatch)
        let card = try #require(vm.card(for: .appleWatch))
        #expect(card.queued?.features == DebugAppInformationContent.iPhoneFeatures.subtracting([.voiceControl]))
        #expect(vm.toast == """
        Copied iPhone’s answers to Apple Watch. Voice Control isn’t available there, so it was left out. Check that they hold on Apple Watch \
        before you publish.
        """)
        #expect(!vm.canCopyFromIPhone(to: .iPhone))
    }

    @Test func copyInsideTheEditorFillsItAndExplains() async {
        let vm = await loaded()
        vm.openEditor(.appleWatch)
        vm.copyIntoEditor()
        #expect(vm.editor?.features == DebugAppInformationContent.iPhoneFeatures.subtracting([.voiceControl]))
        #expect(vm.editorMessage?.hasPrefix("Copied iPhone’s answers to Apple Watch.") == true)
        vm.cancelEditor()
        #expect(vm.editor == nil)
        #expect(queue.changes.isEmpty)
    }

    @Test func deleteDraftIsAPendingChange() async throws {
        let vm = await loaded()
        vm.deleteDraft(.iPad)
        let change = try #require(queue.change(id: vm.builder.accessibilityChangeID(.iPad)))
        #expect(change.requests.first?.method == .delete)
        #expect(vm.card(for: .iPad)?.state == .notDeclared)
        vm.deleteDraft(.iPhone)
        #expect(queue.changes.count == 1)
    }

    @Test func anInvalidURLIsQueuedBlocked() async {
        let vm = await loaded()
        vm.setAccessibilityURL("lumen.example/accessibility")
        #expect(vm.accessibilityURL == "lumen.example/accessibility")
        #expect(vm.accessibilityURLProblem != nil)
        #expect(queue.changes.first?.blockedReason != nil)
        vm.setAccessibilityURL("https://lumen.example/accessibility")
        #expect(queue.changes.isEmpty)
    }

    @Test func aFailedLoadShowsAppleCodeAndTheRequest() async {
        let error = AppStoreConnectError.server(statusCode: 500, code: "UNEXPECTED_ERROR", detail: "An unexpected error occurred.")
        let vm = await loaded(DebugAppInformationServices(accessibilityError: error))
        #expect(vm.accessibility.errorMessage == "Couldn’t load accessibility declarations.")
        #expect(vm.accessibilityErrorLine == "500 · UNEXPECTED_ERROR · GET /v1/apps/\(app.id)/accessibilityDeclarations")
        #expect(vm.status(for: .accessibility) == "Couldn’t load")
        #expect(vm.isLoaded)
    }

    @Test func anIOSAppCanDeclareForTheWatchFromOtherDevices() async {
        let vm = AppInformationViewModel(
            app: StoreApp(id: DebugFixtures.AppID.habitat, name: "Habitat", bundleID: "dev.example.habitat", sku: nil, primaryLocale: "en-US"),
            services: DebugAppInformationServices(),
            queue: queue
        )
        await vm.load()
        #expect(vm.otherFamilies == [.appleWatch])
        vm.openEditor(.appleWatch)
        #expect(vm.editor?.family == .appleWatch)
    }
}
#endif
