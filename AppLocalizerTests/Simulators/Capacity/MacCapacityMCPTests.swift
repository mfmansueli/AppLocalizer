//
//  MacCapacityMCPTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// `thisMac`, as the assistant reads it in the capture plan and steps.
@Suite("MacCapacity · MCP")
struct MacCapacityMCPTests {
    private static func how(_ mac: MacCapacity) -> String {
        mac.mcpJSON.objectValue?["how"]?.stringValue ?? ""
    }

    @Test func aCalmMacSaysHowManyAndToGoDeviceByDevice() {
        let json = MacCapacity(cores: 8, memoryGB: 16, load: 3.2).mcpJSON.objectValue
        #expect(json?["simulatorsAtOnce"] == .int(2))
        #expect(json?["cores"] == .int(8))
        #expect(json?["load"]?.stringValue == "3.2 waiting to run on 8 cores: calm")
        let how = json?["how"]?.stringValue ?? ""
        #expect(how.hasPrefix("Keep at most 2 simulators running at once"))
        #expect(how.contains("xcrun simctl shutdown <simulatorId>"))
        #expect(how.contains("Don't start every device up front"))
        #expect(!how.contains("right now"))
    }

    @Test func aBusyMacIsOneAtATime() {
        let mac = MacCapacity(cores: 8, memoryGB: 16, load: 26)
        #expect(mac.mcpJSON.objectValue?["simulatorsAtOnce"] == .int(1))
        #expect(Self.how(mac).hasPrefix("Keep one simulator running at a time"))
        #expect(Self.how(mac).contains("This Mac is busy right now"))
    }

    @Test func anOverloadedMacStartsNothingNew() {
        let mac = MacCapacity(cores: 8, memoryGB: 16, load: 790)
        #expect(mac.mcpJSON.objectValue?["load"]?.stringValue == "790 waiting to run on 8 cores: overloaded")
        #expect(Self.how(mac).contains("shut down every simulator but the one you're capturing on"))
        #expect(Self.how(mac).contains("start nothing new until the next step says it has settled"))
    }

    @Test func onlyStepsThatUseSimulatorsGetIt() {
        let mac = MacCapacity(cores: 8, memoryGB: 16, load: 2)
        for action in ["capture", "record"] {
            var step: [String: JSONValue] = ["action": .string(action)]
            MacCapacity.addGuidance(to: &step, capacity: mac)
            #expect(step["thisMac"] == mac.mcpJSON)
        }
        for action in ["wait", "design", "write_captions", "done"] {
            var step: [String: JSONValue] = ["action": .string(action)]
            MacCapacity.addGuidance(to: &step, capacity: mac)
            #expect(step["thisMac"] == nil)
        }
        // The capture plan has no action.
        var plan: [String: JSONValue] = ["devices": .array([])]
        MacCapacity.addGuidance(to: &plan, capacity: mac)
        #expect(plan["thisMac"] == mac.mcpJSON)
    }
}
