//
//  ClaudeCodeHelperScript+Repair.swift
//  AppLocalizer
//

import Foundation

/// The helper's modes that put this Mac's simulators right when none will
/// start (`SimulatorRepair`): `repair-simulators` shuts them down and
/// restarts CoreSimulator's service, and `repair-audio` restarts the Mac's
/// audio service first, which simulators need to start. That one is the
/// system's, so macOS asks for an administrator's password; closing the
/// request ends with status 77. Neither takes a value.
extension ClaudeCodeHelperScript {
    static let repairFunctions = #"""
    # Shuts every simulator down and restarts the service that runs them
    # (macOS starts it again when it's next asked).
    restart_simulator_service() {
      with_limit 120 /usr/bin/xcrun simctl shutdown all >/dev/null 2>&1
      /usr/bin/killall -9 com.apple.CoreSimulator.CoreSimulatorService >/dev/null 2>&1
      /bin/sleep 3
      return 0
    }

    repair_simulators() {
      restart_simulator_service
    }

    # The audio service (coreaudiod) is the system's: macOS asks for an
    # administrator's password, and starts it again by itself.
    repair_audio() {
      local why="AppLocalizer wants to restart the audio service of this Mac. Simulators need it to start, and it is stuck."
      local ask="do shell script \"/usr/bin/killall -9 coreaudiod\" with prompt \"$why\" with administrator privileges"
      if ! /usr/bin/osascript -e $ask </dev/null >/dev/null 2>&1; then
        return 77
      fi
      /bin/sleep 3
      restart_simulator_service
    }
    """#
}
