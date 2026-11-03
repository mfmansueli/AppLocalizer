//
//  AutopilotNextStep+MCPRecord.swift
//  AppLocalizer
//

import Foundation

/// `next_step`'s recordings for the App Preview: each device in each
/// language to record, and how.
extension AutopilotNextStep {
    static func recordJSON(targets: [AutopilotRecordingTarget]) -> JSONValue {
        [
            "action": "record",
            "remaining": .int(targets.count),
            "record": .array(targets.map(recordingJSON)),
            "how": .string(AutopilotRun.recordingHow),
        ]
    }

    static func recordingJSON(_ target: AutopilotRecordingTarget) -> JSONValue {
        [
            "displayType": .string(target.displayType.mcpValue),
            "simulator": .string(target.displayType.deviceName),
            "locale": .string(target.locale),
            "launchArguments": .string(StoreLocale.simulatorLaunchArguments(for: target.locale)),
        ]
    }
}
