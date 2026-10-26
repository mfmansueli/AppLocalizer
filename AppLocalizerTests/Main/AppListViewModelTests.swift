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
}
