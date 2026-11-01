//
//  AppListViewModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("AppListViewModel")
struct AppListViewModelTests {
    private let bruma = StoreApp(id: "1", name: "Bruma", bundleID: "com.lima.bruma")
    private let focus = StoreApp(id: "2", name: "Focus Timer", bundleID: "com.lima.focustimer")
    private let wander = StoreApp(id: "3", name: "Wanderlog", bundleID: "com.lima.wanderlog")

    @Test func startsEmptyAndNotLoaded() {
        let vm = AppListViewModel(services: FakeAppListServices())
        #expect(vm.apps.isEmpty)
        #expect(!vm.hasLoaded)
        #expect(!vm.isLoading)
        #expect(vm.selectedApp == nil)
    }

    @Test func loadingSelectsTheFirstApp() async {
        let vm = AppListViewModel(services: FakeAppListServices(apps: [bruma, focus]))
        await vm.load()
        #expect(vm.apps == [bruma, focus])
        #expect(vm.selectedApp == bruma)
        #expect(vm.hasLoaded)
        #expect(!vm.isLoading)
    }

    @Test func refreshKeepsTheSelectionWhenTheAppIsStillThere() async {
        let services = FakeAppListServices(apps: [bruma, focus])
        let vm = AppListViewModel(services: services)
        await vm.load()
        vm.selectedAppID = focus.id
        services.apps = [bruma, focus, wander]
        await vm.load()
        #expect(vm.selectedApp == focus)
    }

    @Test func refreshMovesTheSelectionWhenTheAppIsGone() async {
        let services = FakeAppListServices(apps: [bruma, focus])
        let vm = AppListViewModel(services: services)
        await vm.load()
        vm.selectedAppID = focus.id
        services.apps = [wander]
        await vm.load()
        #expect(vm.selectedApp == wander)
    }

    @Test func emptyAccountLoadsWithNoSelection() async {
        let vm = AppListViewModel(services: FakeAppListServices())
        await vm.load()
        #expect(vm.hasLoaded)
        #expect(vm.selectedApp == nil)
        #expect(vm.errorMessage == nil)
    }

    @Test func failureShowsTheErrorAndKeepsTheLastApps() async {
        let services = FakeAppListServices(apps: [bruma])
        let vm = AppListViewModel(services: services)
        await vm.load()
        services.error = AppStoreConnectError.rateLimited
        await vm.load()
        #expect(vm.errorMessage == AppStoreConnectError.rateLimited.errorDescription)
        #expect(vm.apps == [bruma])
        #expect(!vm.isLoading)
    }

    @Test func successfulRetryClearsTheError() async {
        let services = FakeAppListServices(apps: [bruma])
        services.error = AppStoreConnectError.unauthorized
        let vm = AppListViewModel(services: services)
        await vm.load()
        services.error = nil
        await vm.load()
        #expect(vm.errorMessage == nil)
        #expect(services.loads == 2)
    }

    @Test func searchFiltersTheVisibleApps() async {
        let vm = AppListViewModel(services: FakeAppListServices(apps: [bruma, focus, wander]))
        await vm.load()
        vm.searchText = "focus"
        #expect(vm.visibleApps == [focus])
        #expect(vm.apps.count == 3)
    }

    @Test func keepsTheRestoredSelection() async {
        let vm = AppListViewModel(services: FakeAppListServices(apps: [bruma, focus]), selectedAppID: focus.id)
        await vm.load()
        #expect(vm.selectedApp == focus)
    }

    @Test func remembersWhenItLastSynced() async {
        let vm = AppListViewModel(services: FakeAppListServices(apps: [bruma]))
        #expect(vm.lastSyncedAt == nil)
        await vm.load()
        #expect(vm.lastSyncedAt != nil)
    }

    @Test func sortsTheVisibleAppsByTheChosenOrder() async {
        let vm = AppListViewModel(services: FakeAppListServices(apps: [wander, bruma, focus]))
        await vm.load()
        #expect(vm.sortedVisibleApps { _ in AppIndicators() } == [bruma, focus, wander])
        vm.sortOrder = .unpushedChanges
        let sorted = vm.sortedVisibleApps { AppIndicators(pendingChangeCount: $0 == wander ? 3 : 0) }
        #expect(sorted == [wander, bruma, focus])
    }

    // MARK: - Icons and the team's name

    private let brumaIcon = URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Purple/AppIcon.png/256x256bb.png")!

    @Test func iconsFillInFromEachAppsLatestBuild() async {
        let services = FakeAppListServices(apps: [bruma, focus])
        services.iconURLs = [bruma.id: brumaIcon]
        let vm = AppListViewModel(services: services)
        await vm.load()
        #expect(vm.apps.allSatisfy { $0.icon == nil })

        await vm.loadIcons()
        #expect(services.iconRequests == [bruma.id, focus.id])
        #expect(vm.apps.first { $0.id == bruma.id }?.icon == .remote(brumaIcon))
        // No build yet: it keeps its letter.
        #expect(vm.apps.first { $0.id == focus.id }?.icon == nil)
        #expect(vm.selectedApp?.icon == .remote(brumaIcon))
    }

    @Test func aReloadKeepsTheIconsAndOnlyAsksForTheMissingOnes() async {
        let services = FakeAppListServices(apps: [bruma, focus])
        services.iconURLs = [bruma.id: brumaIcon]
        let vm = AppListViewModel(services: services)
        await vm.load()
        await vm.loadIcons()

        await vm.load()
        #expect(vm.apps.first { $0.id == bruma.id }?.icon == .remote(brumaIcon))
        await vm.loadIcons()
        #expect(services.iconRequests == [bruma.id, focus.id, focus.id])
    }

    @Test func anAppThatDrawsItsOwnIconIsntAsked() async {
        let lumen = StoreApp(id: "4", name: "Lumen", bundleID: "dev.northpier.lumen", icon: .symbol("moon.fill", top: 0x7C86FF, bottom: 0x3A2FB8))
        let services = FakeAppListServices(apps: [lumen])
        let vm = AppListViewModel(services: services)
        await vm.load()
        await vm.loadIcons()
        #expect(services.iconRequests.isEmpty)
        #expect(vm.apps == [lumen])
    }

    @Test func aFailedIconKeepsTheLetter() async {
        let services = FakeAppListServices(apps: [bruma])
        services.iconError = AppStoreConnectError.forbidden(detail: nil)
        let vm = AppListViewModel(services: services)
        await vm.load()
        await vm.loadIcons()
        #expect(vm.apps.first?.icon == nil)
        #expect(vm.errorMessage == nil)
    }

    @Test func theTeamsNameComesFromTheServices() async {
        let services = FakeAppListServices()
        services.teamName = "Lima Apps"
        #expect(await AppListViewModel(services: services).findTeamName() == "Lima Apps")
    }

    @Test func aRoleThatCantReadTheTeamsNameFindsNone() async {
        let services = FakeAppListServices()
        services.teamName = "Lima Apps"
        services.teamNameError = AppStoreConnectError.forbidden(detail: nil)
        #expect(await AppListViewModel(services: services).findTeamName() == nil)
    }
}
