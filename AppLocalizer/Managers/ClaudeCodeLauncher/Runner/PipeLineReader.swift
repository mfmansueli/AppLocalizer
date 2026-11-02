//
//  PipeLineReader.swift
//  AppLocalizer
//

import Foundation

/// A pipe's lines as they arrive, each pipe read on its own.
///
/// `FileHandle.bytes` reads every handle in the process on one serial
/// queue, with a blocking `read`: while one pipe has nothing to say (the
/// helper's stderr, say), no other pipe is read. Claude Code's output then
/// filled its pipe, and the helper waited for hours to print its last line,
/// and every later call to the helper waited behind it. Here each pipe has
/// its own readability handler.
///
/// The pipe is drained to its end even when nobody listens any more, so
/// the script writing to it never waits on AppLocalizer.
enum PipeLineReader {
    /// The lines `handle` reads until its end: split at "\n", "\r\n" or
    /// "\r" (a progress line), and the last one even without a line break.
    /// The handle is closed at the end.
    static func lines(of handle: FileHandle) -> AsyncStream<String> {
        let (stream, continuation) = AsyncStream<String>.makeStream()
        let splitter = PipeLineSplitter()
        handle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                try? handle.close()
                if let last = splitter.finish() { continuation.yield(last) }
                continuation.finish()
                return
            }
            for line in splitter.append(data) {
                continuation.yield(line)
            }
        }
        return stream
    }
}
