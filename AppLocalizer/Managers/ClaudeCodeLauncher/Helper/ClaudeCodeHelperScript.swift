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
/// a platform's simulator, `create-simulator` makes one. Each takes only
/// fixed values, checked by the script, never a command.
enum ClaudeCodeHelperScript {
    /// Bumped when the script changes; an older one asks to be saved again.
    static let version = 3

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
    # applocalizer-helper 3

    emulate -L zsh
    setopt no_nomatch

    helper_version=3

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

    case $1 in
      check)
        check
        ;;
      simulators|install-platform|create-simulator)
        mode=$1
        shift
        case $mode in
          simulators) list_simulators ;;
          install-platform) install_platform "$@" ;;
          create-simulator) create_simulator "$@" ;;
        esac
        code=$?
        print -r -- "applocalizer-helper-exit $code"
        exit $code
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
    install-platform <platform> | create-simulator <name> <type> <runtime>"
        exit 64
        ;;
    esac

    """#
}
