//
//  SimulatorInventoryTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Reading `simctl`'s list, and whether each device can be captured on this
/// Mac: iPhone Duo needs iOS 27.1, which a Mac with Xcode 27.2 may not have.
@Suite("Simulator inventory")
struct SimulatorInventoryTests {
    private static func inventory(newRuntime: Bool = false, duo: Bool = false) throws -> SimulatorInventory {
        try SimulatorInventory.parse(DebugSimulators.json(DebugSimulators.Mac(hasNewRuntime: newRuntime, hasDuo: duo)))
    }

    @Test func aMadeSimulatorIsReady() throws {
        let inventory = try Self.inventory()
        #expect(inventory.status(for: .iPhone) == .ready(simulator: "iPhone 17 Pro Max", runtime: "iOS 27.0"))
        #expect(inventory.status(for: .iPad) == .ready(simulator: "iPad Pro 13-inch (M5)", runtime: "iOS 27.0"))
        #expect(inventory.status(for: .watch) == .ready(simulator: "Apple Watch Ultra 3 (49mm)", runtime: "watchOS 27.0"))
        #expect(inventory.status(for: .iPhone).detail == "iPhone 17 Pro Max · iOS 27.0")
    }

    @Test func iPhoneDuoNeedsANewerRuntime() throws {
        let status = try Self.inventory().status(for: .iPhoneDuo)
        #expect(status == .needsRuntime(platform: "iOS", minimumVersion: "27.1", installed: ["iOS 26.5", "iOS 27.0"]))
        #expect(!status.canCapture)
        #expect(status.platformToInstall == "iOS")
        #expect(status.detail == "Needs the iOS 27.1 simulator or later. This Mac has \(["iOS 26.5", "iOS 27.0"].formatted(.list(type: .and))).")
    }

    @Test func withoutTheVisionOSSimulatorVisionProCantBeCaptured() throws {
        let status = try Self.inventory().status(for: .visionPro)
        #expect(status == .needsRuntime(platform: "visionOS", minimumVersion: "3.0", installed: []))
        #expect(status.detail.hasSuffix("This Mac has no visionOS simulator."))
    }

    @Test func onceTheRuntimeIsThereTheSimulatorCanBeMadeThenItsReady() throws {
        let makeable = try Self.inventory(newRuntime: true).status(for: .iPhoneDuo)
        #expect(makeable == .canMake(
            deviceType: "iPhone Duo", deviceTypeID: "com.apple.CoreSimulator.SimDeviceType.iPhone-Duo",
            runtime: "iOS 27.2", runtimeID: "com.apple.CoreSimulator.SimRuntime.iOS-27-2"
        ))
        #expect(makeable.canCapture)
        #expect(makeable.platformToInstall == nil)
        #expect(try Self.inventory(newRuntime: true, duo: true).status(for: .iPhoneDuo) == .ready(simulator: "iPhone Duo", runtime: "iOS 27.2"))
    }

    @Test func aDeviceThisXcodeDoesntKnowNeedsANewerXcode() throws {
        var inventory = try Self.inventory()
        inventory.deviceTypes.removeAll { $0.name == "iPhone Duo" }
        #expect(inventory.status(for: .iPhoneDuo) == .needsNewerXcode(deviceName: "iPhone Duo"))
    }

    @Test func anOlderDeviceTypeOfTheSameSizeWillDo() throws {
        let json = """
        {"runtimes":[{"identifier":"rt.ios18","name":"iOS 18.5","version":"18.5","platform":"iOS","isAvailable":true,\
        "supportedDeviceTypes":[{"identifier":"type.16pm","name":"iPhone 16 Pro Max"}]}],\
        "devicetypes":[{"identifier":"type.17pm","name":"iPhone 17 Pro Max","minRuntimeVersionString":"26.0.0"},\
        {"identifier":"type.16pm","name":"iPhone 16 Pro Max","minRuntimeVersionString":"18.0.0"}],"devices":{}}
        """
        let status = try SimulatorInventory.parse(json).status(for: .iPhone)
        #expect(status == .canMake(deviceType: "iPhone 16 Pro Max", deviceTypeID: "type.16pm", runtime: "iOS 18.5", runtimeID: "rt.ios18"))
    }

    @Test func simctlsOwnListIsRead() throws {
        // As `xcrun simctl list -j runtimes devicetypes devices` prints it,
        // with fields AppLocalizer doesn't use.
        let json = """
        {"devicetypes":[{"productFamily":"iPhone","bundlePath":"/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone Duo.simdevicetype",\
        "maxRuntimeVersion":4294967295,"maxRuntimeVersionString":"65535.255.255","identifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-Duo",\
        "modelIdentifier":"iPhone19,4","minRuntimeVersionString":"27.1.0","minRuntimeVersion":1769728,"name":"iPhone Duo"}],\
        "runtimes":[{"isAvailable":true,"version":"27.0","isInternal":false,"buildversion":"24A434","supportedArchitectures":["arm64"],\
        "supportedDeviceTypes":[],"identifier":"com.apple.CoreSimulator.SimRuntime.iOS-27-0","platform":"iOS","name":"iOS 27.0",\
        "lastUsage":{"arm64":"2026-11-01T22:16:38Z"}}],\
        "devices":{"com.apple.CoreSimulator.SimRuntime.iOS-27-0":[{"dataPath":"/x","dataPathSize":1,"logPath":"/y","udid":"BC207193",\
        "isAvailable":true,"deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro","state":"Shutdown","name":"iPhone 17 Pro"}]}}
        """
        let inventory = try SimulatorInventory.parse(json)
        #expect(inventory.deviceTypes.first?.minRuntimeVersionString == "27.1.0")
        #expect(inventory.devices.values.first?.first?.name == "iPhone 17 Pro")
        #expect(inventory.status(for: .iPhoneDuo) == .needsRuntime(platform: "iOS", minimumVersion: "27.1", installed: ["iOS 27.0"]))
    }

    /// iPhone Duo's watcher looks at the simulator the captures come from:
    /// a running one first, so it sees the one the assistant uses.
    @Test func theDevicesSimulatorIsTheRunningOneFirst() throws {
        var mac = DebugSimulators.Mac(hasNewRuntime: true, hasDuo: true)
        let shutDown = try #require(SimulatorInventory.parse(DebugSimulators.json(mac)).simulator(for: .iPhoneDuo))
        #expect(shutDown.udid == "00000000-0000-0000-0000-000000000004")
        #expect(shutDown.state == "Shutdown")
        #expect(!shutDown.isBooted)

        mac.duoIsBooted = true
        #expect(try SimulatorInventory.parse(DebugSimulators.json(mac)).simulator(for: .iPhoneDuo)?.isBooted == true)
        #expect(try Self.inventory().simulator(for: .iPhoneDuo) == nil, "None made")
        #expect(try Self.inventory().simulator(for: .iPhone)?.name == "iPhone 17 Pro Max")

        let json = """
        {"runtimes": [{"identifier": "r", "name": "iOS 27.2", "version": "27.2", "isAvailable": true,
          "supportedDeviceTypes": [{"identifier": "duo"}]}],
         "devicetypes": [{"identifier": "duo", "name": "iPhone Duo"}],
         "devices": {"r": [
           {"udid": "A", "name": "iPhone Duo", "deviceTypeIdentifier": "duo", "isAvailable": true, "state": "Shutdown"},
           {"udid": "B", "name": "iPhone Duo (2)", "deviceTypeIdentifier": "duo", "isAvailable": true, "state": "Booted"}]}}
        """
        #expect(try SimulatorInventory.parse(json).simulator(for: .iPhoneDuo)?.udid == "B")
    }

    @Test func versionsAreShortened() {
        #expect(SimulatorInventory.shortVersion("27.1.0") == "27.1")
        #expect(SimulatorInventory.shortVersion("27.0.0") == "27.0")
        #expect(SimulatorInventory.shortVersion("17.4.1") == "17.4.1")
        #expect(SimulatorInventory.shortVersion("27.1") == "27.1")
    }

    @Test func eachDeviceHasItsPlatform() {
        #expect(ScreenshotDisplayType.iPhoneDuo.simulatorPlatform == "iOS")
        #expect(ScreenshotDisplayType.watch.simulatorPlatform == "watchOS")
        #expect(ScreenshotDisplayType.visionPro.simulatorPlatform == "visionOS")
        #expect(ScreenshotDisplayType.visionPro.simulatorRuntimePlatforms.contains("xrOS"))
        #expect(ScreenshotDisplayType.iPhone.simulatorDeviceTypes.first == ScreenshotDisplayType.iPhone.deviceName)
    }
}
#endif
