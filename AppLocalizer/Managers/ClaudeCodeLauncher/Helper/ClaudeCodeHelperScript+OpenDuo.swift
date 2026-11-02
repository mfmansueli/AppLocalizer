//
//  ClaudeCodeHelperScript+OpenDuo.swift
//  AppLocalizer
//

import Foundation

/// The program the helper's `open-duo` writes to a temporary folder and runs
/// with `xcrun swift`: iPhone Duo's simulator starts closed and no command
/// opens it, so it shows the Duo's own window in Device Hub
/// (`devices://device/open?id=`), presses Open in its poses with macOS's
/// accessibility features, closes the window, and gives the Mac back to the
/// app that was in front. Device Hub shows its windows to accessibility only
/// while it's in front, and on macOS 27 a script sees Device Hub's process
/// only through `pgrep` (`NSRunningApplication` says -1), so the helper
/// passes the front app's process from `lsappinfo`. It prints pressed,
/// accessibility-needed, no-device-hub or no-open-button.
extension ClaudeCodeHelperScript {
    /// The script's `accessibility` and `open-duo` modes; `open-duo` writes
    /// `openDuoProgram` out and runs it.
    static let openDuoFunctions = #"""
    # Whether macOS lets AppLocalizer use accessibility features, which pressing
    # Open in Device Hub takes: `trusted` or `not-trusted`. With `prompt`, macOS
    # asks you, and lists AppLocalizer in Privacy & Security › Accessibility.
    accessibility() {
      local options=null
      [[ $1 == prompt ]] && options='$({AXTrustedCheckOptionPrompt: true})'
      local trusted
      trusted=$(with_limit 20 /usr/bin/osascript -l JavaScript \
        -e 'ObjC.import("ApplicationServices")' -e "\$.AXIsProcessTrustedWithOptions($options)" 2>/dev/null)
      if [[ $trusted == true ]]; then
        print -r -- trusted
      else
        print -r -- not-trusted
      fi
    }

    # iPhone Duo's simulator starts closed and no command opens it: Device Hub's
    # window for it has the poses. This shows that window, presses Open, closes
    # the window, and gives the Mac back to the app that was in front. Prints
    # pressed, accessibility-needed, no-device-hub or no-open-button.
    open_duo() {
      local udid=$1 name=$2
      if ! is_identifier $udid || [[ -z $name || $name == -* || $name == *[[:cntrl:]]* ]]; then
        print -u2 -r -- "Usage: open-duo <udid> <name>"
        return 64
      fi
      if [[ $(accessibility) != trusted ]]; then
        print -r -- accessibility-needed
        return 77
      fi
      local front=0 info
      info=$(/usr/bin/lsappinfo info -only pid "$(/usr/bin/lsappinfo front)" 2>/dev/null)
      [[ $info =~ 'pid"?[[:space:]]*=[[:space:]]*([0-9]+)' ]] && front=$match[1]
      local folder
      folder=$(/usr/bin/mktemp -d -t applocalizer-duo) || return 73
      /bin/cat > $folder/open-duo.swift <<'SWIFT'
    \#(openDuoProgram)
    SWIFT
      with_limit 120 /usr/bin/xcrun swift $folder/open-duo.swift $udid $name $front
      local code=$?
      /bin/rm -rf -- $folder
      return $code
    }
    """#

    static let openDuoProgram = #"""
    import AppKit
    import ApplicationServices

    // open-duo.swift <udid> <name> <front>: shows the device's window in Device
    // Hub, presses Open in its poses and closes the window, then gives the Mac
    // back to the app that was in front (its process, or 0).
    let udid = CommandLine.arguments[1]
    let name = CommandLine.arguments[2]
    let frontProcess = pid_t(CommandLine.arguments[3]) ?? 0

    func finish(_ word: String, _ code: Int32) -> Never {
        print(word)
        exit(code)
    }

    func value(_ element: AXUIElement, _ attribute: String) -> AnyObject? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value
    }

    func elements(_ element: AXUIElement, _ attribute: String) -> [AXUIElement] {
        (value(element, attribute) as? [AXUIElement]) ?? []
    }

    func text(_ element: AXUIElement, _ attribute: String) -> String {
        (value(element, attribute) as? String) ?? ""
    }

    func set(_ element: AXUIElement, _ attribute: String, _ on: Bool) {
        AXUIElementSetAttributeValue(element, attribute as CFString, on ? kCFBooleanTrue : kCFBooleanFalse)
    }

    /// Device Hub's process, if it's running.
    func hubProcess() -> pid_t? {
        let pgrep = Process()
        pgrep.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        pgrep.arguments = ["-x", "DeviceHub"]
        let output = Pipe()
        pgrep.standardOutput = output
        guard (try? pgrep.run()) != nil else { return nil }
        pgrep.waitUntilExit()
        let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        return text.split(whereSeparator: \.isNewline).first.flatMap { pid_t($0) }
    }

    /// The device's window: Device Hub's windows aren't always in AXWindows,
    /// but the one the link just showed is its focused or main window.
    func window(of app: AXUIElement) -> AXUIElement? {
        let candidates = ["AXFocusedWindow", "AXMainWindow"].compactMap { value(app, $0) }.map { $0 as! AXUIElement }
            + elements(app, "AXWindows")
        return candidates.first { text($0, "AXTitle").hasPrefix(name) }
    }

    /// The poses follow Home, Screenshot, Record and Rotate in the window's
    /// controls: Closed, Partially Open, Open. Open is the last.
    func openButton(in window: AXUIElement) -> AXUIElement? {
        var queue = [window]
        while !queue.isEmpty {
            let element = queue.removeFirst()
            let children = elements(element, "AXChildren")
            let buttons = children.filter { text($0, "AXRole") == "AXButton" }
            if let record = buttons.firstIndex(where: { text($0, "AXIdentifier") == "record.circle" }) {
                let after = buttons[(record + 1)...]
                if let open = after.first(where: { text($0, "AXDescription") == "Open" }) { return open }
                return after.count == 4 ? after.last : nil
            }
            // Not the device's own screen.
            queue += children.filter { text($0, "AXSubrole") != "iOSContentGroup" }
        }
        return nil
    }

    guard AXIsProcessTrusted() else { finish("accessibility-needed", 77) }
    let wasRunning = hubProcess() != nil

    /// Device Hub hides again if this started it; the app that was in front
    /// comes back.
    func giveBack(hiding hub: AXUIElement?) {
        if let hub, !wasRunning { set(hub, "AXHidden", true) }
        if frontProcess > 0, frontProcess != hubProcess() { set(AXUIElementCreateApplication(frontProcess), "AXFrontmost", true) }
    }

    // Device Hub shows the device's window, and comes to the front: only then
    // does it show its windows to accessibility.
    let opener = Process()
    opener.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    opener.arguments = ["devices://device/open?id=\(udid)"]
    guard (try? opener.run()) != nil else { finish("no-device-hub", 69) }
    opener.waitUntilExit()
    guard opener.terminationStatus == 0 else { finish("no-device-hub", 69) }

    var hub: AXUIElement?
    var found: (window: AXUIElement, button: AXUIElement)?
    // Device Hub may be starting, and the window connecting to the device.
    for _ in 0 ..< 60 {
        if let process = hubProcess() {
            let app = AXUIElementCreateApplication(process)
            AXUIElementSetMessagingTimeout(app, 5)
            hub = app
            if let window = window(of: app), let button = openButton(in: window) {
                found = (window, button)
                break
            }
        }
        Thread.sleep(forTimeInterval: 0.5)
    }
    guard let found else {
        giveBack(hiding: nil)
        finish(hub == nil ? "no-device-hub" : "no-open-button", 69)
    }
    guard AXUIElementPerformAction(found.button, kAXPressAction as CFString) == .success else {
        giveBack(hiding: nil)
        finish("no-open-button", 69)
    }
    // The hinge opens over a moment; closing the window keeps the pose.
    Thread.sleep(forTimeInterval: 3)
    if let close = elements(found.window, "AXChildren").first(where: { text($0, "AXSubrole") == "AXCloseButton" }) {
        AXUIElementPerformAction(close, kAXPressAction as CFString)
    }
    giveBack(hiding: hub)
    finish("pressed", 0)
    """#
}
