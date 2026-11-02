//
//  ClaudeCodeHelperScript+Simulators.swift
//  AppLocalizer
//

import Foundation

/// The helper's modes for this Mac's simulators, which Screenshot
/// Autopilot's plan checks before a run (`MacSimulators`): `simulators`
/// lists them, `install-platform` downloads a platform's simulator, and
/// `create-simulator` makes one. Each takes only fixed values, checked here.
extension ClaudeCodeHelperScript {
    /// The script's `simulators`, `install-platform` and `create-simulator`
    /// modes.
    static let simulatorFunctions = #"""
    list_simulators() {
      /usr/bin/xcrun simctl list -j runtimes devicetypes devices </dev/null
    }

    # Only the platforms xcodebuild downloads; its progress goes to stdout.
    install_platform() {
      case $1 in
        iOS|watchOS|visionOS|tvOS) ;;
        *)
          print -u2 -r -- "Not a simulator platform: $1"
          return 64
          ;;
      esac
      /usr/bin/xcodebuild -downloadPlatform $1 </dev/null 2>&1
    }

    # A name, and CoreSimulator's identifiers for the device type and runtime.
    create_simulator() {
      local name=$1 type=$2 runtime=$3
      if [[ -z $name || $name == -* || $name == *[[:cntrl:]]* ]] \
        || [[ $type != com.apple.CoreSimulator.SimDeviceType.* || $type == *[^A-Za-z0-9.-]* ]] \
        || [[ $runtime != com.apple.CoreSimulator.SimRuntime.* || $runtime == *[^A-Za-z0-9.-]* ]]; then
        print -u2 -r -- "Usage: create-simulator <name> <device type> <runtime>"
        return 64
      fi
      /usr/bin/xcrun simctl create $name $type $runtime </dev/null
    }
    """#
}
