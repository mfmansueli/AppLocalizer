//
//  AccountSettingsViewModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("AccountSettingsViewModel")
struct AccountSettingsViewModelTests {
    private let northpier = TestKeys.credentials(keyID: "2X9R4HXF34", teamName: "Northpier Studio")
    private let brightline = TestKeys.credentials(keyID: "Q7MZ3K8PLA", teamName: "Brightline Apps")
    private let checker = FakeKeyChecker()

    private func model(_ store: FakeCredentialsStore? = nil) -> AccountSettingsViewModel {
        AccountSettingsViewModel(session: AppSession(store: store ?? FakeCredentialsStore(stored: [northpier, brightline])), checker: checker)
    }

    @Test func listsTheSavedKeysAndTheOneInUse() {
        let vm = model()
        #expect(vm.keys.map(\.keyID) == ["2X9R4HXF34", "Q7MZ3K8PLA"])
        #expect(vm.isInUse("2X9R4HXF34"))
        #expect(!vm.isInUse("Q7MZ3K8PLA"))
        #expect(vm.account(for: brightline).name == "Brightline Apps")
    }

    @Test func connectionTestRecordsWhatTheKeyCanDo() async {
        let vm = model()
        checker.result.salesAccess = .notAllowed
        await vm.test(keyID: brightline.keyID)
        #expect(checker.checked == [brightline])
        #expect(vm.check(for: brightline.keyID)?.salesAccess == .notAllowed)
        #expect(vm.session.checks[brightline.keyID] != nil)
        #expect(!vm.isTesting(brightline.keyID))
    }

    @Test func progressShowsWhileTheTestRuns() async {
        let vm = model()
        var wasTesting = false
        checker.whileChecking = { wasTesting = vm.isTesting(northpier.keyID) }
        await vm.test(keyID: northpier.keyID)
        #expect(wasTesting)
    }

    @Test func failedTestIsShownAndAPassingOneClearsIt() async {
        let vm = model()
        checker.error = AppStoreConnectError.unauthorized
        await vm.test(keyID: northpier.keyID)
        #expect(vm.failure(for: northpier.keyID) == .rejected)

        checker.error = nil
        await vm.test(keyID: northpier.keyID)
        #expect(vm.failure(for: northpier.keyID) == nil)
        #expect(vm.check(for: northpier.keyID) != nil)
    }

    @Test func unknownKeysAreNotTested() async {
        let vm = model()
        await vm.test(keyID: "NOTSAVED00")
        #expect(checker.checked.isEmpty)
    }

    @Test func useSwitchesTheKeyInUse() {
        let vm = model()
        vm.use(keyID: brightline.keyID)
        #expect(vm.isInUse(brightline.keyID))
    }

    @Test func removeAndRenameGoThroughTheSession() {
        let vm = model()
        vm.rename(keyID: brightline.keyID, to: "Brightline Labs")
        #expect(vm.account(for: vm.keys[1]).name == "Brightline Labs")
        vm.remove(keyID: northpier.keyID)
        #expect(vm.keys.map(\.keyID) == ["Q7MZ3K8PLA"])
        #expect(vm.isInUse("Q7MZ3K8PLA"))
        #expect(vm.errorMessage == nil)
    }

    @Test func keychainFailuresAreShown() {
        let store = FakeCredentialsStore(stored: [northpier])
        store.deleteError = KeychainError(status: errSecAuthFailed)
        let vm = model(store)
        vm.remove(keyID: northpier.keyID)
        #expect(vm.errorMessage == KeychainError(status: errSecAuthFailed).errorDescription)
        #expect(vm.keys == [northpier])
    }
}
