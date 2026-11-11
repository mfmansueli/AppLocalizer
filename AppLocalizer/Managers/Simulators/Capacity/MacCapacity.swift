//
//  MacCapacity.swift
//  AppLocalizer
//

import Foundation

/// How many simulators this Mac can run at once without grinding to a
/// halt, for Screenshot Autopilot: from its cores and memory, and from how
/// busy it is right now. Alba's run had iPhone, iPhone Duo, iPad and Apple
/// Watch started together on 8 cores: a load of 800, a capture every few
/// minutes, an estimate of 22 hours, and Safari wouldn't open a page.
struct MacCapacity: Hashable, Sendable {
    var cores: Int
    var memoryGB: Double
    /// The load average of the last minute: runnable processes, so about
    /// `cores` when the Mac is exactly busy.
    var load: Double

    /// A simulator keeps about this many cores busy while it starts and
    /// runs a UI test.
    static let coresPerSimulator = 4
    /// And about this much memory.
    static let memoryPerSimulatorGB = 6.0
    /// Never more at once, whatever the Mac.
    static let mostSimulators = 4

    /// This Mac, now.
    static var current: MacCapacity {
        var averages = [Double](repeating: 0, count: 3)
        let read = getloadavg(&averages, 3)
        let info = ProcessInfo.processInfo
        return MacCapacity(
            cores: info.activeProcessorCount,
            memoryGB: Double(info.physicalMemory) / 1_073_741_824,
            load: read > 0 ? averages[0] : 0
        )
    }

    /// The load for each core: 1 is a Mac exactly busy.
    var loadPerCore: Double {
        load / Double(max(cores, 1))
    }

    var pressure: MacPressure {
        MacPressure(loadPerCore: loadPerCore)
    }

    /// The simulators it runs well side by side when it has nothing else
    /// to do.
    var roomForSimulators: Int {
        let byCores = cores / Self.coresPerSimulator
        let byMemory = Int(memoryGB / Self.memoryPerSimulatorGB)
        return min(max(min(byCores, byMemory), 1), Self.mostSimulators)
    }

    /// The simulators to keep running at once right now: one when the Mac
    /// is already busy.
    var simulatorsAtOnce: Int {
        pressure == .calm ? roomForSimulators : 1
    }
}
