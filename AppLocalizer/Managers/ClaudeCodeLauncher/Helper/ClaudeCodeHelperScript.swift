//
//  ClaudeCodeHelperScript.swift
//  AppLocalizer
//

import Foundation

/// The helper that lets AppLocalizer start Claude Code. The app is
/// sandboxed, so it can't start other programs; macOS runs the scripts in
/// `~/Library/Application Scripts/<bundle ID>/` for it, outside the sandbox
/// (`NSUserUnixTask`). The app can't write that folder either, so the person
/// saves this script there once from a Save panel
/// (`ClaudeCodeHelperInstaller`).
///
/// The script stays small and generic, so it rarely needs saving again:
/// `check` says where Claude Code is, and `run <folder> -- <arguments…>`
/// runs it in the app's project folder with the arguments AppLocalizer
/// builds (`ClaudeCodeInvocation`), streaming its output, and prints
/// `exitMarker` with the status when it ends (Claude Code's own last lines
/// can still follow it). A line on stdin, or stdin closing, stops it.
///
/// Screenshot Autopilot also asks it about the Mac's simulators
/// (`MacSimulators`): `simulators` lists them, `install-platform` downloads
/// a platform's simulator, `create-simulator` makes one. For iPhone Duo,
/// whose simulator starts closed and can get stuck (`DuoWatcher`), it reads
/// a simulator's displays (`simulator-displays`), screenshots one small
/// (`simulator-screenshot`), lists the SpringBoard crashes since it started
/// (`simulator-crashes`), starts or shuts it down (`boot-simulator`,
/// `shutdown-simulator`), and opens it (`open-duo`): no command does, so it
/// shows the Duo's window in Device Hub, presses Open in its poses with
/// macOS's accessibility features, closes the window and gives the Mac back
/// to the app that was in front. That needs AppLocalizer allowed in
/// Accessibility, which `accessibility` checks and asks for. A UI test's
/// screenshot on the Duo is its cover display, so it records the inner
/// display while the test runs (`record-display`), reads when the test took
/// each screenshot (`test-results`), and gives back the frame from then
/// (`recorded-frame`, `discard-recording`; `DisplayRecorder`). Each takes
/// only fixed values, checked by the script, never a command.
enum ClaudeCodeHelperScript {
    /// Bumped when the script changes; an older one asks to be saved again.
    static let version = 6

    /// The oldest helper that still starts Claude Code: version 2's `run`
    /// is this one's, so a run in progress doesn't stop for the update.
    /// Version 1 could lose a run's end.
    static let minimumRunVersion = 2

    /// The name the Save panel suggests.
    static let fileName = "Start Claude Code.zsh"

    /// The line `run` prints when Claude Code ends: `applocalizer-helper-exit 0`.
    static let exitMarker = "applocalizer-helper-exit"

    /// What `check` answered.
    enum CheckResult: Hashable, Sendable {
        case found(ClaudeCodeInstallation)
        /// The helper ran but found no `claude`.
        case claudeMissing(helperVersion: Int)
        /// Not the helper's answer.
        case unreadable
    }

    /// Reads `check`'s lines: `helper 1`, then `claude <path>` and `version
    /// <text>`, or `claude-missing`.
    static func parseCheck(_ output: String) -> CheckResult {
        var helperVersion: Int?
        var path: String?
        var versionText: String?
        var isMissing = false
        for line in output.split(whereSeparator: \.isNewline).map(String.init) {
            if let value = value(of: "helper", in: line) {
                helperVersion = Int(value)
            } else if line == "claude-missing" {
                isMissing = true
            } else if let value = value(of: "claude", in: line) {
                path = value
            } else if let value = value(of: "version", in: line) {
                versionText = value
            }
        }
        guard let helperVersion else { return .unreadable }
        if isMissing { return .claudeMissing(helperVersion: helperVersion) }
        guard let path, !path.isEmpty else { return .unreadable }
        return .found(ClaudeCodeInstallation(
            path: path,
            version: versionText.map(ClaudeCodeInstallation.shortVersion) ?? "",
            helperVersion: helperVersion
        ))
    }

    /// The status in `run`'s last line, if `line` is it.
    static func exitStatus(in line: String) -> Int32? {
        guard let value = value(of: exitMarker, in: line) else { return nil }
        return Int32(value)
    }

    private static func value(of key: String, in line: String) -> String? {
        let prefix = key + " "
        guard line.hasPrefix(prefix) else { return nil }
        return String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
    }

    /// The script's text, as saved.
    static let contents = #"""
    #!/bin/zsh -f
    # Start Claude Code for AppLocalizer.
    #
    # AppLocalizer is sandboxed, so it can't start other programs. macOS runs the
    # scripts in ~/Library/Application Scripts/com.lima.applocalizer/ for it,
    # outside the sandbox, and AppLocalizer only runs this one when you ask it to
    # start Claude Code. It finds Claude Code, goes to your app's project folder
    # and runs `claude` there with the arguments AppLocalizer passes. Delete this
    # file any time: AppLocalizer goes back to copying prompts.
    #
    #   check                          this script's version and where Claude Code is
    #   run <folder> -- <arguments…>   runs Claude Code in <folder>; a line on stdin,
    #                                  or stdin closing, stops it
    #
    # For Screenshot Autopilot, when you ask for it in AppLocalizer:
    #
    #   simulators                     lists this Mac's simulators (xcrun simctl list)
    #   install-platform <platform>    downloads the iOS, watchOS or visionOS
    #                                  simulator (xcodebuild -downloadPlatform)
    #   create-simulator <name> <device type> <runtime>
    #                                  makes a simulator (xcrun simctl create)
    #
    # And for iPhone Duo, whose simulator starts closed and can get stuck:
    #
    #   simulator-displays <udid>      a simulator's displays (xcrun simctl io enumerate)
    #   simulator-screenshot <udid> <display>
    #                                  one display's screenshot, 256 pixels high, as base64
    #   simulator-crashes <udid>       its SpringBoard crash reports since it started
    #   boot-simulator <udid>          starts it and waits until it has (xcrun simctl bootstatus -b)
    #   shutdown-simulator <udid>      shuts it down (xcrun simctl shutdown)
    #   open-duo <udid> <name>         opens it: shows its window in Device Hub, presses
    #                                  Open in its poses and closes the window again
    #   accessibility [prompt]         whether macOS lets AppLocalizer press it (Privacy &
    #                                  Security › Accessibility); with prompt, macOS asks
    #   record-display <udid> <display>
    #                                  captures a display again and again, full size, until
    #                                  a line on stdin, into a temporary folder
    #   test-results <bundle> [<test>] a UI test result bundle's tests, or when one test
    #                                  took its screenshots (xcrun xcresulttool)
    #   recorded-frame <frame>         one recorded frame, as base64
    #   discard-recording <folder>     deletes a recording
    #
    # applocalizer-helper 6

    emulate -L zsh
    setopt no_nomatch

    helper_version=6

    # Where Claude Code is: its own installer's folder first, then package
    # managers, then whatever your login shell finds.
    find_claude() {
      local candidate
      for candidate in \
        $HOME/.local/bin/claude \
        $HOME/.claude/local/claude \
        /opt/homebrew/bin/claude \
        /usr/local/bin/claude \
        $HOME/.npm-global/bin/claude \
        $HOME/.volta/bin/claude \
        $HOME/.bun/bin/claude \
        $HOME/Library/pnpm/claude \
        $HOME/.local/share/pnpm/claude \
        $HOME/.asdf/shims/claude \
        $HOME/.local/share/mise/shims/claude; do
        if [[ -x $candidate ]]; then
          print -r -- $candidate
          return 0
        fi
      done
      # nvm: the newest Node version that has it.
      local nvm=( ${NVM_DIR:-$HOME/.nvm}/versions/node/*/bin/claude(N-*n) )
      if (( $#nvm )); then
        print -r -- ${nvm[-1]}
        return 0
      fi
      local shell_path
      for shell_path in "$(/bin/zsh -lc 'command -v claude' </dev/null 2>/dev/null)" \
                        "$(/bin/zsh -lic 'command -v claude' </dev/null 2>/dev/null | tail -n 1)"; do
        if [[ $shell_path == /* && -x $shell_path ]]; then
          print -r -- $shell_path
          return 0
        fi
      done
      return 1
    }

    check() {
      print -r -- "helper $helper_version"
      local claude
      if ! claude=$(find_claude); then
        print -r -- "claude-missing"
        return 3
      fi
      print -r -- "claude $claude"
      print -r -- "version $($claude --version 2>/dev/null </dev/null | head -n 1)"
    }

    run_claude() {
      local folder=$1
      shift
      [[ $1 == -- ]] && shift
      local claude
      if ! claude=$(find_claude); then
        print -u2 -r -- "Claude Code isn't installed."
        return 127
      fi
      if ! cd -- $folder 2>/dev/null; then
        print -u2 -r -- "The project folder $folder isn't there."
        return 66
      fi
      # A Node-based install finds node beside it.
      path=( ${claude:h} $path )
      # Claude Code writes through pipes of its own, with cat passing its lines
      # on: Node leaves the pipe it writes to non-blocking, and on AppLocalizer's
      # one that loses the last lines and the exit line below whenever
      # AppLocalizer is a moment behind ("write error: resource temporarily
      # unavailable"). $! is still Claude Code's.
      $claude "$@" </dev/null > >(cat) 2> >(cat >&2) &
      local pid=$!
      # AppLocalizer keeps stdin open while the run goes on. A line, or stdin
      # closing because AppLocalizer quit, stops Claude Code. (A script's
      # background job ignores interrupts, so it's a terminate; Claude Code has
      # saved the session as it went, so it can be resumed.)
      {
        read -r _
        kill -TERM $pid 2>/dev/null
      } &
      local watcher=$!
      wait $pid
      local code=$?
      kill $watcher 2>/dev/null
      return $code
    }

    \#(simulatorFunctions)

    # A simulator's or display's identifier, as simctl prints it.
    is_identifier() {
      [[ ${#1} == 36 && $1 != *[^0-9A-F-]* ]]
    }

    # Runs a command for at most <seconds>: a stuck simulator can keep simctl
    # waiting. The timer has no pipes of AppLocalizer's, so it never holds the
    # answer back.
    with_limit() {
      local seconds=$1
      shift
      "$@" </dev/null &
      local pid=$!
      ( /bin/sleep $seconds && kill -TERM $pid ) </dev/null >/dev/null 2>&1 &
      local timer=$!
      wait $pid
      local code=$?
      kill $timer 2>/dev/null
      return $code
    }

    simulator_displays() {
      if ! is_identifier $1; then
        print -u2 -r -- "Usage: simulator-displays <udid>"
        return 64
      fi
      with_limit 30 /usr/bin/xcrun simctl io $1 enumerate
    }

    # Small, so it fits on one line: enough to tell black, a spinner and an
    # app apart.
    simulator_screenshot() {
      local udid=$1 display=$2
      if ! is_identifier $udid || ! is_identifier $display; then
        print -u2 -r -- "Usage: simulator-screenshot <udid> <display>"
        return 64
      fi
      local folder
      folder=$(/usr/bin/mktemp -d -t applocalizer-display) || return 73
      local file=$folder/display.png code=0
      if with_limit 30 /usr/bin/xcrun simctl io $udid screenshot --display=$display $file >/dev/null \
        && /usr/bin/sips -Z 256 $file >/dev/null 2>&1; then
        /usr/bin/base64 -i $file
      else
        code=69
      fi
      /bin/rm -rf -- $folder
      return $code
    }

    # The SpringBoard crash reports written since the simulator started (its
    # launchd_bootstrap.plist is written then): the time and name of each.
    simulator_crashes() {
      if ! is_identifier $1; then
        print -u2 -r -- "Usage: simulator-crashes <udid>"
        return 64
      fi
      local started=$HOME/Library/Developer/CoreSimulator/Devices/$1/data/var/run/launchd_bootstrap.plist
      [[ -f $started ]] || return 0
      local report
      for report in $HOME/Library/Logs/DiagnosticReports/SpringBoard-*.ips(N.); do
        [[ $report -nt $started ]] || continue
        if /usr/bin/grep -q "SimDevice.$1" $report; then
          print -r -- "$(/usr/bin/stat -f %m $report) ${report:t}"
        fi
      done
      return 0
    }

    boot_simulator() {
      if ! is_identifier $1; then
        print -u2 -r -- "Usage: boot-simulator <udid>"
        return 64
      fi
      with_limit 300 /usr/bin/xcrun simctl bootstatus $1 -b 2>&1
    }

    shutdown_simulator() {
      if ! is_identifier $1; then
        print -u2 -r -- "Usage: shutdown-simulator <udid>"
        return 64
      fi
      with_limit 120 /usr/bin/xcrun simctl shutdown $1
    }

    \#(openDuoFunctions)

    \#(recordingFunctions)

    # A simulator mode's output, then the exit line.
    simulator_mode() {
      local mode=$1
      shift
      case $mode in
        simulators) list_simulators ;;
        install-platform) install_platform "$@" ;;
        create-simulator) create_simulator "$@" ;;
        simulator-displays) simulator_displays "$@" ;;
        simulator-screenshot) simulator_screenshot "$@" ;;
        simulator-crashes) simulator_crashes "$@" ;;
        boot-simulator) boot_simulator "$@" ;;
        shutdown-simulator) shutdown_simulator "$@" ;;
        open-duo) open_duo "$@" ;;
        accessibility) accessibility "$@" ;;
        record-display) record_display "$@" ;;
        test-results) test_results "$@" ;;
        recorded-frame) recorded_frame "$@" ;;
        discard-recording) discard_recording "$@" ;;
      esac
      local code=$?
      print -r -- "applocalizer-helper-exit $code"
      exit $code
    }

    case $1 in
      check)
        check
        ;;
      simulators|install-platform|create-simulator|simulator-displays|simulator-screenshot|simulator-crashes)
        simulator_mode "$@"
        ;;
      boot-simulator|shutdown-simulator|open-duo|accessibility)
        simulator_mode "$@"
        ;;
      record-display|test-results|recorded-frame|discard-recording)
        simulator_mode "$@"
        ;;
      run)
        shift
        run_claude "$@"
        code=$?
        print -r -- "applocalizer-helper-exit $code"
        exit $code
        ;;
      *)
        print -u2 -r -- "Usage: ${0:t} check | run <folder> -- <claude arguments…> | simulators | \#
    install-platform <platform> | create-simulator <name> <type> <runtime> | simulator-displays <udid> | \#
    simulator-screenshot <udid> <display> | simulator-crashes <udid> | boot-simulator <udid> | shutdown-simulator <udid> | \#
    open-duo <udid> <name> | accessibility [prompt] | record-display <udid> <display> | test-results <bundle> [<test>] | \#
    recorded-frame <frame> | discard-recording <folder>"
        exit 64
        ;;
    esac

    """#
}
