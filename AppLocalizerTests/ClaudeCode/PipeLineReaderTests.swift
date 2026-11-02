//
//  PipeLineReaderTests.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
import Testing
@testable import AppLocalizer

/// Reading the helper's pipes: a quiet stderr never holds Claude Code's
/// output back (it did with `FileHandle.bytes`, and the helper waited for
/// hours to print its last line), and a pipe nobody listens to any more is
/// still drained.
@Suite("Pipe line reader")
struct PipeLineReaderTests {
    /// More than a pipe holds (64 KB), so a writer would wait if the pipe
    /// weren't read.
    private static let lineCount = 2000
    private static let line = Data((String(repeating: "x", count: 200) + "\n").utf8)

    /// A value threads and tasks share.
    private final class Shared<Value: Sendable>: Sendable {
        private let value: Mutex<Value>

        init(_ value: Value) {
            self.value = Mutex(value)
        }

        var current: Value { value.withLock { $0 } }

        func change(_ body: @Sendable (inout Value) -> Void) {
            value.withLock { body(&$0) }
        }
    }

    /// Writes `lineCount` lines on a thread of its own, then closes the
    /// pipe; `done` turns true once every write went through.
    private static func write(to pipe: Pipe, done: Shared<Bool>? = nil) {
        let handle = pipe.fileHandleForWriting
        Thread.detachNewThread {
            for _ in 0..<lineCount {
                handle.write(line)
            }
            try? handle.close()
            done?.change { $0 = true }
        }
    }

    private static func waitUntil(_ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + .seconds(5)
        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test func aQuietPipeDoesntHoldAnotherBack() async {
        let output = Pipe()
        let errors = Pipe()
        let quiet = PipeLineReader.lines(of: errors.fileHandleForReading)
        let quietTask = Task { for await _ in quiet {} }
        let lines = PipeLineReader.lines(of: output.fileHandleForReading)
        Self.write(to: output)

        let count = Shared(0)
        let reading = Task {
            for await _ in lines {
                count.change { $0 += 1 }
            }
        }
        await Self.waitUntil { count.current == Self.lineCount }
        #expect(count.current == Self.lineCount)

        try? errors.fileHandleForWriting.close()
        await quietTask.value
        await reading.value
    }

    @Test func aPipeNobodyListensToIsStillDrained() async {
        let output = Pipe()
        let lines = PipeLineReader.lines(of: output.fileHandleForReading)
        let listening = Task { for await _ in lines {} }
        listening.cancel()
        await listening.value

        let written = Shared(false)
        Self.write(to: output, done: written)
        await Self.waitUntil { written.current }
        #expect(written.current, "The writer never waits")
    }

    @Test func linesEndAtAnyLineBreakAndTheLastNeedsNone() async {
        let pipe = Pipe()
        let lines = PipeLineReader.lines(of: pipe.fileHandleForReading)
        let handle = pipe.fileHandleForWriting
        for chunk in ["{\"type\":\"sys", "tem\"}\n", "Downloading 10%\rDownloading 20%\r", "\nDone\r\n", "applocalizer-helper-exit 0"] {
            handle.write(Data(chunk.utf8))
            try? await Task.sleep(for: .milliseconds(20))
        }
        try? handle.close()

        var read: [String] = []
        for await line in lines {
            read.append(line)
        }
        #expect(read == ["{\"type\":\"system\"}", "Downloading 10%", "Downloading 20%", "Done", "applocalizer-helper-exit 0"])
    }

    @Test func theSplitterKeepsAHalfLineAndUTF8() {
        let splitter = PipeLineSplitter()
        let text = Data("Língua: 日本語\r".utf8)
        // Cut inside the "í".
        #expect(splitter.append(text.prefix(2)).isEmpty)
        #expect(splitter.append(text.dropFirst(2)) == ["Língua: 日本語"])
        #expect(splitter.append(Data("\n\nok".utf8)) == [""], "The \\n after a \\r isn't a line of its own")
        #expect(splitter.finish() == "ok")
        #expect(splitter.finish() == nil)
    }
}
