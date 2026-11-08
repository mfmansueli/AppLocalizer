//
//  UnitTestHost.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The unit tests run inside the app, which would otherwise open the MCP
/// port and keep the Autopilot runs on disk like the person's own
/// AppLocalizer. The port is opened with endpoint reuse, so tests run while
/// it's open (a live Bruma run capturing) could take its assistant's calls
/// and write their stale runs over its own. As a test host it does neither.
enum UnitTestHost {
    static var isRunning: Bool { isRunning(in: ProcessInfo.processInfo.environment) }

    static func isRunning(in environment: [String: String]) -> Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}
#endif
