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
