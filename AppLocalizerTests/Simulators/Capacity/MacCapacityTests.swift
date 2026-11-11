//
//  MacCapacityTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("MacCapacity")
struct MacCapacityTests {
    private static func mac(cores: Int = 8, memoryGB: Double = 16, load: Double = 2) -> MacCapacity {
        MacCapacity(cores: cores, memoryGB: memoryGB, load: load)
    }

    @Test func roomComesFromCoresAndMemory() {
        #expect(Self.mac(cores: 8, memoryGB: 16).roomForSimulators == 2)
        #expect(Self.mac(cores: 4, memoryGB: 16).roomForSimulators == 1)
        #expect(Self.mac(cores: 12, memoryGB: 36).roomForSimulators == 3)
        // Plenty of cores, little memory.
        #expect(Self.mac(cores: 16, memoryGB: 8).roomForSimulators == 1)
    }

    @Test func thereIsAlwaysRoomForOneAndNeverForMoreThanFour() {
        #expect(Self.mac(cores: 2, memoryGB: 4).roomForSimulators == 1)
        #expect(Self.mac(cores: 0, memoryGB: 0).roomForSimulators == 1)
        #expect(Self.mac(cores: 32, memoryGB: 128).roomForSimulators == MacCapacity.mostSimulators)
    }

    @Test func aCalmMacRunsAllItHasRoomFor() {
        let mac = Self.mac(load: 6)
        #expect(mac.pressure == .calm)
        #expect(mac.simulatorsAtOnce == 2)
    }

    @Test func aBusyMacRunsOneAtATime() {
        let mac = Self.mac(load: 24)
        #expect(mac.pressure == .busy)
        #expect(mac.simulatorsAtOnce == 1)
    }

    /// Alba's run: four simulators started together on 8 cores.
    @Test func aLoadInTheHundredsIsOverloaded() {
        let mac = Self.mac(load: 790)
        #expect(mac.pressure == .overloaded)
        #expect(mac.simulatorsAtOnce == 1)
    }

    @Test func pressureGoesByTheLoadForEachCore() {
        #expect(MacPressure(loadPerCore: 0) == .calm)
        #expect(MacPressure(loadPerCore: MacPressure.busyLoadPerCore - 0.1) == .calm)
        #expect(MacPressure(loadPerCore: MacPressure.busyLoadPerCore) == .busy)
        #expect(MacPressure(loadPerCore: MacPressure.overloadedLoadPerCore) == .overloaded)
        // The same load is calm on a Mac with more cores.
        #expect(Self.mac(cores: 16, memoryGB: 64, load: 24).pressure == .calm)
    }

    @Test func thisMacCanBeRead() {
        let mac = MacCapacity.current
        #expect(mac.cores >= 1)
        #expect(mac.memoryGB > 0)
        #expect(mac.load >= 0)
        #expect((1...MacCapacity.mostSimulators).contains(mac.simulatorsAtOnce))
    }
}
