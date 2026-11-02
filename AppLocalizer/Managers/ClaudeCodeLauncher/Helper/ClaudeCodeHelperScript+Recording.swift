//
//  ClaudeCodeHelperScript+Recording.swift
//  AppLocalizer
//

import Foundation

/// The helper's modes for iPhone Duo's inner display during a UI test
/// (`DisplayRecorder`). A UI test's screenshot on the Duo is its cover
/// display, and the test closes the app a moment after taking it, too soon
/// for a command run afterwards. So `record-display` captures the display at
/// full size again and again while the test runs, `test-results` reads from
/// the result bundle when the test took each screenshot, `recorded-frame`
/// gives back the frame taken just before, and `discard-recording` deletes
/// the rest.
extension ClaudeCodeHelperScript {
    /// The script's `record-display`, `test-results`, `recorded-frame` and
    /// `discard-recording` modes.
    static let recordingFunctions = #"""
    # One display of a simulator at full size, captured again and again until
    # AppLocalizer says stop (a line on stdin, or stdin closing), for at most ten
    # minutes. Prints `folder <path>`, then `frame <start> <end> <file>` for each
    # capture (seconds since 1970, like XCTest's times), `same <end>` when one
    # matched the frame before it, and `dropped <file>` when the oldest frame
    # goes, so a recording keeps at most 200.
    record_display() {
      local udid=$1 display=$2
      if ! is_identifier $udid || ! is_identifier $display; then
        print -u2 -r -- "Usage: record-display <udid> <display>"
        return 64
      fi
      zmodload zsh/datetime
      local tmp=${TMPDIR:-/tmp}
      # Recordings left behind when AppLocalizer quit, an hour on.
      /bin/rm -rf -- ${tmp%/}/applocalizer-recording.*(N/mh+1)
      local folder
      folder=$(/usr/bin/mktemp -d -t applocalizer-recording) || return 73
      print -r -- "folder $folder"
      { read -r _; : >$folder/.stop } &
      local watcher=$!
      local -a kept
      local start end file last= failures=0 code=0
      local deadline=$(( EPOCHSECONDS + 600 ))
      while [[ ! -e $folder/.stop ]] && (( EPOCHSECONDS < deadline )); do
        printf -v start '%.3f' $EPOCHREALTIME
        if ! with_limit 30 /usr/bin/xcrun simctl io $udid screenshot --display=$display $folder/capture.png >/dev/null 2>&1; then
          if (( ++failures >= 10 )); then
            print -u2 -r -- "The simulator's display stopped answering."
            code=69
            break
          fi
          /bin/sleep 0.5
          continue
        fi
        failures=0
        printf -v end '%.3f' $EPOCHREALTIME
        if [[ -n $last ]] && /usr/bin/cmp -s $folder/capture.png $folder/$last; then
          print -r -- "same $end"
          continue
        fi
        file=frame-$start-$end.png
        /bin/mv -f $folder/capture.png $folder/$file
        kept+=( $file )
        last=$file
        print -r -- "frame $start $end $file"
        if (( ${#kept} > 200 )); then
          /bin/rm -f -- $folder/$kept[1]
          print -r -- "dropped $kept[1]"
          kept=( $kept[2,-1] )
        fi
      done
      kill $watcher 2>/dev/null
      /bin/rm -f -- $folder/capture.png $folder/.stop
      return $code
    }

    # When a UI test took each screenshot it attached: a result bundle's tests,
    # or one test's activities with their times (xcrun xcresulttool, as JSON).
    test_results() {
      local bundle=$1 test=$2
      if [[ $bundle != /*.xcresult || $bundle == *[[:cntrl:]]* || ! -d $bundle ]] \
        || [[ -n $test && ( $test == -* || $test == *[[:cntrl:]]* ) ]]; then
        print -u2 -r -- "Usage: test-results <bundle.xcresult> [<test>]"
        return 64
      fi
      if [[ -z $test ]]; then
        with_limit 60 /usr/bin/xcrun xcresulttool get test-results tests --path $bundle
      else
        with_limit 60 /usr/bin/xcrun xcresulttool get test-results activities --test-id $test --path $bundle
      fi
    }

    # A recording's folder, as record-display made it.
    is_recording() {
      [[ $1 == /* && $1 != *..* && $1 != *[[:cntrl:]]* && ${1:t} == applocalizer-recording.* && -d $1 && -O $1 ]]
    }

    # One recorded frame, full size, as base64.
    recorded_frame() {
      if ! is_recording ${1:h} || [[ ${1:t} != frame-*.png || ! -f $1 ]]; then
        print -u2 -r -- "Usage: recorded-frame <frame>"
        return 64
      fi
      /usr/bin/base64 -i $1
    }

    discard_recording() {
      if ! is_recording $1; then
        print -u2 -r -- "Usage: discard-recording <folder>"
        return 64
      fi
      /bin/rm -rf -- $1
    }
    """#
}
