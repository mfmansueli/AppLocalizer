//
//  ReviewPushViewModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("ReviewPushViewModel")
struct ReviewPushViewModelTests {
    private let queue = ChangeQueue()

    private func makeViewModel(selectedAppID: StoreApp.ID? = "lumen", confirmation: PushConfirmation = .overFifty) -> ReviewPushViewModel {
        let push = PushController(queue: queue, history: PushHistory(), transport: FakePushTransport())
        return ReviewPushViewModel(
            queue: queue,
            push: push,
            selectedAppID: selectedAppID,
            appName: { $0 == "lumen" ? "Lumen Journal" : "Habitat" },
            pushConfirmation: confirmation
        )
    }

    private func fill() {
        queue.upsert(contentsOf: [
            PushFixtures.price("BRA"),
            PushFixtures.price("MEX"),
            PushFixtures.listing("Subtitle", source: .machineTranslation),
            PushFixtures.listing("Keywords", source: .assistant(client: "Claude Code")),
            PushFixtures.listing("Name", app: "habitat"),
        ])
    }

    @Test func opensOnTheSelectedAppWhenItHasChanges() {
        fill()
        let vm = makeViewModel()
        #expect(vm.scope == .thisApp)
        #expect(vm.thisAppCount == 4)
        #expect(vm.allAppsCount == 5)
        #expect(makeViewModel(selectedAppID: "quiet").scope == .allApps)
    }

    @Test func groupsByAppThenHeading() {
        fill()
        let vm = makeViewModel()
        vm.scope = .allApps
        #expect(vm.appGroups.map(\.appName) == ["Lumen Journal", "Habitat"])
        #expect(vm.appGroups[0].groups.map(\.title) == ["Subscription Pricing · Annual", "Store Page · version 1.4"])
        #expect(vm.appGroups[0].groups[0].changes.count == 2)
        #expect(vm.appGroups[0].groups[0].groupID == "annual")
    }

    @Test func sourceFilterCountsEachSourceInScope() {
        fill()
        let vm = makeViewModel()
        #expect(vm.sourceOptions.map(\.title) == ["All", "You", "Machine translation", "Claude Code"])
        #expect(vm.sourceOptions.map(\.count) == [4, 2, 1, 1])
        vm.sourceFilter = .machineTranslation
        #expect(vm.visibleChanges.map(\.id) == ["listing.de.Subtitle"])
        #expect(vm.assistantsInScope.isEmpty)
        vm.sourceFilter = nil
        #expect(vm.assistantsInScope == ["Claude Code"])
    }

    @Test func blockedChangesNeedAttentionAndArentPushable() {
        fill()
        var blocked = PushFixtures.price("ARG")
        blocked.remoteConflict = RemoteConflict(remoteRawValue: "1", remoteDisplayValue: "$1")
        queue.upsert(blocked)
        let vm = makeViewModel()
        #expect(vm.attentionCount == 1)
        #expect(vm.subtitle == "5 changes · 1 needs attention")
        #expect(vm.pushableChanges.count == 4)
        #expect(!vm.pushableChanges.contains { $0.id == blocked.id })
    }

    @Test func selectionPushesOnlyCheckedChanges() async {
        fill()
        let vm = makeViewModel()
        vm.toggle("price.annual.BRA")
        #expect(vm.selectedPushableChanges.map(\.id) == ["price.annual.BRA"])
        #expect(vm.estimate.requestCount == 1)
        vm.startPush(vm.selectedPushableChanges)
        await vm.push.waitUntilFinished()
        #expect(queue.change(id: "price.annual.BRA") == nil)
        #expect(vm.selection.isEmpty)
        #expect(queue.totalCount == 4)
    }

    @Test func discardAllRemovesOnlyWhatShows() {
        fill()
        let vm = makeViewModel()
        vm.sourceFilter = .you
        vm.discardVisible()
        #expect(queue.changes.map(\.id) == ["listing.de.Subtitle", "listing.de.Keywords", "listing.de.Name"])
    }

    @Test func rejectingAnAssistantDropsItsProposalsAndResetsTheFilter() {
        fill()
        let vm = makeViewModel()
        vm.sourceFilter = .assistant("Claude Code")
        vm.rejectAll(fromAssistant: "Claude Code")
        #expect(vm.sourceFilter == nil)
        #expect(!queue.changes.contains { $0.source.isAssistant })
    }

    @Test func largePushesAndPriceIncreasesAskFirst() {
        let vm = makeViewModel()
        let small = [PushFixtures.price("BRA")]
        #expect(vm.confirmationMessage(for: small) == nil)
        let increase = [PushFixtures.price("BRA", delta: 12)]
        #expect(vm.confirmationMessage(for: increase)?.contains("1 prices go up") == true)
        let many = (0..<51).map { PushFixtures.price("T\($0)") }
        #expect(vm.confirmationMessage(for: many)?.contains("51 changes") == true)
        #expect(makeViewModel(confirmation: .never).confirmationMessage(for: many) == nil)
    }
}
