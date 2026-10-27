//
//  ReviewPushViewModelScreenshotsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Screenshots in Review & Push: counts in the header and scope, image and
/// set checkboxes, Push Selected and the footer's estimate.
@MainActor
@Suite("ReviewPushViewModel+Screenshots")
struct ReviewPushViewModelScreenshotsTests {
    private func loadedViewModel() async -> ReviewPushViewModel {
        let queue = ChangeQueue()
        let push = PushController(queue: queue, history: PushHistory(), transport: FakePushTransport())
        let harness = ScreenshotPushControllerHarness(controller: push.screenshots)
        let app = harness.app
        let viewModel = ReviewPushViewModel(queue: queue, push: push, selectedAppID: app.id, appName: { _ in app.name })
        await viewModel.loadScreenshotPlans(refreshCount: 0)
        return viewModel
    }

    @Test func imagesCountInTheHeaderAndScope() async {
        let viewModel = await loadedViewModel()
        #expect(viewModel.imagesCountTitle == "40 images in 8 sets")
        #expect(viewModel.imagesSubtitle?.hasPrefix("40 images in 8 sets · old → new for each slot.") == true)
        #expect(viewModel.thisAppCount == 40)
        #expect(viewModel.allAppsCount == 40)
        #expect(viewModel.showsScreenshots)
    }

    @Test func uncheckingSomeImagesMakesThemPushSelected() async throws {
        let viewModel = await loadedViewModel()
        let first = try #require(viewModel.visibleImages.first)
        #expect(!viewModel.hasPartialImageSelection)
        #expect(viewModel.allPushCount == 40)
        #expect(viewModel.selectedPushCount == 0)
        #expect(viewModel.selectedTitleCount == 40)

        viewModel.toggle(first)
        #expect(!viewModel.isChecked(first))
        #expect(viewModel.hasPartialImageSelection)
        #expect(viewModel.selectedPushCount == 39)
    }

    @Test func aSetsCheckboxIsMixedUntilToggled() async throws {
        let viewModel = await loadedViewModel()
        let group = try #require(viewModel.screenshotPlans.first?.groups.first)
        #expect(viewModel.checkState(of: group) == true)
        viewModel.toggle(group.items[0])
        #expect(viewModel.checkState(of: group) == nil)
        viewModel.toggle(group)
        #expect(viewModel.checkState(of: group) == true)
        viewModel.toggle(group)
        #expect(viewModel.checkState(of: group) == false)
    }

    @Test func theFooterEstimatesEveryImage() async {
        let viewModel = await loadedViewModel()
        #expect(viewModel.imagesEstimateText == "About 168 requests · 2 min · 5% of the hourly limit")
    }

    @Test func discardingEveryVisibleImageLeavesThemForUndo() async {
        let viewModel = await loadedViewModel()
        viewModel.discardVisibleImages()
        #expect(viewModel.visibleImages.isEmpty)
        #expect(viewModel.keptImages.count == 40)
        await viewModel.undoImageDiscards()
        #expect(viewModel.visibleImages.count == 40)
    }

    @Test func theSourceFilterAppliesToImages() async {
        let viewModel = await loadedViewModel()
        viewModel.sourceFilter = .machineTranslation
        #expect(viewModel.visibleImages.allSatisfy { $0.source == .machineTranslation })
        #expect(viewModel.visibleImages.count < 40)
    }
}
#endif
