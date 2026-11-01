//
//  AutopilotSimulatorLaunchTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// How the assistant launches the app in each language, and the simulator
/// setup runs from before the permissions option still read.
@Suite("Autopilot simulator launch")
struct AutopilotSimulatorLaunchTests {
    /// iOS's own language codes (`nb`, not App Store Connect's `no`) and
    /// the App Store country's dates, numbers and currency.
    @Test(arguments: [
        ("de-DE", "-AppleLanguages (de) -AppleLocale de_DE"),
        ("ja", "-AppleLanguages (ja) -AppleLocale ja_JP"),
        ("no", "-AppleLanguages (nb) -AppleLocale nb_NO"),
        ("zh-Hans", "-AppleLanguages (zh-Hans) -AppleLocale zh-Hans_CN"),
        ("pt-BR", "-AppleLanguages (pt-BR) -AppleLocale pt_BR"),
        ("en-GB", "-AppleLanguages (en-GB) -AppleLocale en_GB"),
        ("es-MX", "-AppleLanguages (es-MX) -AppleLocale es_MX"),
    ])
    func eachLocaleLaunchesInItsLanguageAndCountry(code: String, arguments: String) {
        #expect(StoreLocale.simulatorLaunchArguments(for: code) == arguments)
    }

    @Test func aCodeTheCatalogDoesntKnowLaunchesAsItIs() {
        #expect(StoreLocale.simulatorLaunchArguments(for: "xx-YY") == "-AppleLanguages (xx-YY) -AppleLocale xx_YY")
    }

    /// The same language and country for UI tests, as xcodebuild flags:
    /// nothing goes in front of xcodebuild, so AppLocalizer's own Claude
    /// Code may run them.
    @Test(arguments: [
        ("de-DE", "-testLanguage de -testRegion DE"),
        ("ja", "-testLanguage ja -testRegion JP"),
        ("no", "-testLanguage nb -testRegion NO"),
        ("zh-Hans", "-testLanguage zh-Hans -testRegion CN"),
        ("pt-BR", "-testLanguage pt-BR -testRegion BR"),
        ("pt-PT", "-testLanguage pt-PT -testRegion PT"),
        ("en-GB", "-testLanguage en-GB -testRegion GB"),
        ("xx-YY", "-testLanguage xx-YY -testRegion YY"),
        ("xx", "-testLanguage xx"),
    ])
    func uiTestsGetTheLanguageAndCountryFromXcodebuild(code: String, arguments: String) {
        #expect(StoreLocale.xcodebuildTestArguments(for: code) == arguments)
    }

    @Test func aSetupFromBeforeThePermissionsOptionGrantsThem() throws {
        let old = Data(#"{"overridesStatusBar":true,"usesSampleData":true,"sampleDataSteps":"","lightAppearance":true,"extraCommands":[]}"#.utf8)
        var setup = try JSONDecoder().decode(AutopilotSimulatorSetup.self, from: old)
        #expect(setup.grantsPermissionsUpFront == nil)
        #expect(setup.grantsPermissions)
        #expect(setup.sampleDataInEachLanguage, "Sample data in each language unless turned off")
        setup.grantsPermissions = false
        let decoded = try JSONDecoder().decode(AutopilotSimulatorSetup.self, from: JSONEncoder().encode(setup))
        #expect(!decoded.grantsPermissions)
        #expect(AutopilotSimulatorSetup.permissionsCommand(bundleID: "dev.northpier.lumen") == "xcrun simctl privacy booted grant all dev.northpier.lumen")
    }
}
#endif
