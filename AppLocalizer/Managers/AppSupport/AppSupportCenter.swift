//
//  AppSupportCenter.swift
//  AppLocalizer
//

import Foundation
import Observation

/// What each app's Xcode project supports, as its assistant reported it:
/// the devices and languages Store Page, Screenshots and the overview
/// compare with the App Store page. Also remembers the languages the
/// person said Not Now to.
@MainActor
@Observable
final class AppSupportCenter {
    static let shared = AppSupportCenter(persistence: FileAppSupportPersistence())

    private(set) var profiles: [StoreApp.ID: AppSupportProfile]
    private(set) var declinedLanguages: [StoreApp.ID: Set<String>]
    @ObservationIgnored private let persistence: (any AppSupportPersistence)?

    init(persistence: (any AppSupportPersistence)? = nil, profiles: [StoreApp.ID: AppSupportProfile] = [:]) {
        self.persistence = persistence
        let archive = persistence?.load() ?? AppSupportArchive()
        self.profiles = archive.profiles.merging(profiles) { $1 }
        declinedLanguages = archive.declinedLanguages
    }

    func profile(for appID: StoreApp.ID) -> AppSupportProfile? {
        profiles[appID]
    }

    /// The assistant read the project again: its report replaces the last,
    /// but for the look, which stays until a report has one.
    func report(_ profile: AppSupportProfile, for appID: StoreApp.ID) {
        var profile = profile
        if profile.look == nil { profile.look = profiles[appID]?.look }
        profiles[appID] = profile
        save()
    }

    /// The project's languages the App Store page doesn't have, without the
    /// ones the person said Not Now to.
    func pendingLanguages(for appID: StoreApp.ID, storeLocales: [String]) -> [ProjectLanguage] {
        let declined = declinedLanguages[appID] ?? []
        return (profiles[appID]?.languagesMissing(from: storeLocales) ?? []).filter { language in
            language.storeLocale.map { !declined.contains($0.code) } ?? false
        }
    }

    /// Every language the project has and the App Store page doesn't,
    /// declined or not.
    func missingLanguages(for appID: StoreApp.ID, storeLocales: [String]) -> [ProjectLanguage] {
        profiles[appID]?.languagesMissing(from: storeLocales) ?? []
    }

    /// The project language that becomes `storeLocale`, if any.
    func language(for appID: StoreApp.ID, storeLocale: String) -> ProjectLanguage? {
        profiles[appID]?.languages.first { $0.storeLocale?.code == storeLocale }
    }

    func isDeclined(_ storeLocale: String, for appID: StoreApp.ID) -> Bool {
        declinedLanguages[appID]?.contains(storeLocale) ?? false
    }

    /// Not Now: the language stops being suggested until the person adds it.
    func decline(_ storeLocale: String, for appID: StoreApp.ID) {
        declinedLanguages[appID, default: []].insert(storeLocale)
        save()
    }

    func undecline(_ storeLocale: String, for appID: StoreApp.ID) {
        guard declinedLanguages[appID]?.remove(storeLocale) != nil else { return }
        save()
    }

    private func save() {
        persistence?.save(AppSupportArchive(profiles: profiles, declinedLanguages: declinedLanguages))
    }
}
