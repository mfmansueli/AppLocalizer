//
//  ReviewPushViewModelOptionTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The review sheet's option switches and the footer line about them.
@MainActor
@Suite("ReviewPushViewModel · options")
struct ReviewPushViewModelOptionTests {
    private let queue = ChangeQueue()

    private func makeViewModel() -> ReviewPushViewModel {
        ReviewPushViewModel(
            queue: queue,
            push: PushController(queue: queue, history: PushHistory(), transport: FakePushTransport(), secrets: InMemorySecretStore()),
            selectedAppID: "lumen",
            appName: { _ in "Lumen Journal" }
        )
    }

    @Test func theFooterCountsWhatPublishesImmediately() {
        queue.upsert(contentsOf: [
            ChangeOptionTests.change(id: "iphone", option: ChangeOptionTests.option()),
            ChangeOptionTests.change(id: "ipad", option: ChangeOptionTests.option()),
            ChangeOptionTests.change(id: "vision", option: ChangeOptionTests.option(isOn: false, disabledReason: "No live version.")),
            PushFixtures.price("BRA"),
        ])
        let vm = makeViewModel()
        #expect(vm.optionFootnotes == ["2 declarations publish"])

        vm.setOption("ipad", isOn: false)
        #expect(vm.optionFootnotes == ["1 declaration publishes"])
        #expect(queue.change(id: "ipad")?.option?.isOn == false)

        vm.toggle("iphone")
        #expect(vm.optionFootnotes == ["1 declaration publishes"])
        vm.toggle("iphone")
        vm.toggle("vision")
        #expect(vm.optionFootnotes.isEmpty)
    }

    @Test func theEstimateCountsTheOptionsRequests() {
        queue.upsert(ChangeOptionTests.change(id: "iphone", option: ChangeOptionTests.option()))
        let vm = makeViewModel()
        #expect(vm.estimate.requestCount == 2)
        vm.setOption("iphone", isOn: false)
        #expect(vm.estimate.requestCount == 1)
    }
}
