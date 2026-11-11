//
//  MacPressure.swift
//  AppLocalizer
//

import Foundation

/// How busy this Mac is, from its load for each core (`MacCapacity`).
enum MacPressure: String, Hashable, Sendable {
    /// Room for more.
    case calm
    /// More waits to run than it has cores: one simulator at a time.
    case busy
    /// Far more: nothing new should start until it settles.
    case overloaded

    /// Simulators running UI tests keep a Mac a little over 1 by
    /// themselves, so busy starts above that.
    static let busyLoadPerCore = 2.5
    static let overloadedLoadPerCore = 8.0

    init(loadPerCore: Double) {
        self = loadPerCore >= Self.overloadedLoadPerCore ? .overloaded : loadPerCore >= Self.busyLoadPerCore ? .busy : .calm
    }
}
