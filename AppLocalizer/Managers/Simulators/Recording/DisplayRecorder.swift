//
//  DisplayRecorder.swift
//  AppLocalizer
//

import Foundation
import Synchronization

/// Records iPhone Duo's inner display while the assistant runs a UI test on
/// it, then gives, for each screenshot the test attached, the frame taken
/// just before (`RecordedFramePick`). A UI test's own screenshot on the Duo
/// is its cover display (`XCUIScreen.main`), and the test closes the app a
/// moment after taking it, too soon for a `simctl` screenshot afterwards.
/// Through the helper: `record-display` until it's finished, `test-results`
/// for when the test took each screenshot, `recorded-frame` for each frame
/// kept, then `discard-recording`. One recording at a time: a new one
/// discards the one before.
@MainActor
final class DisplayRecorder {
    /// A screenshot the test took, and the frame kept for it: its PNG at
    /// full size, nil when none was recorded before it, it couldn't be read,
    /// or the test ran on another simulator.
    struct Shot: Sendable {
        var pick: RecordedFramePick
        var png: Data?
        var isOnOtherSimulator = false
    }

    enum Failure: Error, Equatable, LocalizedError {
        /// The helper is from before it could record.
        case olderHelper
        case didntStart(String?)
        case notRecording
        case unreadableResults(String?)

        var errorDescription: String? {
            switch self {
            case .olderHelper:
                String(localized: "The helper is from before AppLocalizer could record iPhone Duo: the person saves it again.")
            case let .didntStart(reason):
                String(localized: "AppLocalizer couldn’t record iPhone Duo’s inner display") + (reason.map { ": \($0)" } ?? ".")
            case .notRecording:
                String(localized: "Nothing is being recorded: call start_display_recording before running the UI test.")
            case let .unreadableResults(reason):
                String(localized: "AppLocalizer couldn’t read the result bundle") + (reason.map { ": \($0)" } ?? ".")
            }
        }
    }

    /// What the helper prints, as it comes, from its own threads.
    private final class Output: Sendable {
        let recording = Mutex(DisplayRecording())
        let hasEnded = Mutex(false)
    }

    private weak var simulators: MacSimulators?
    private var task: Task<SimulatorHelperAnswer, Never>?
    private var output: Output?
    /// The simulator being recorded.
    private(set) var udid: String?
    /// How long `start` waits for the first frame.
    var firstFrameLimit: Duration = .seconds(20)

    init(simulators: MacSimulators) {
        self.simulators = simulators
    }

    var isRecording: Bool {
        task != nil
    }

    // MARK: - Recording

    /// Starts recording `display` of simulator `udid`, and returns once the
    /// first frame is in.
    func start(udid: String, display: String) async throws {
        guard let simulators else { throw Failure.didntStart(nil) }
        await discard()
        let output = Output()
        self.output = output
        self.udid = udid
        let task = Task {
            let answer = await simulators.run(["record-display", udid, display]) { line in
                output.recording.withLock { $0.read(line) }
            }
            output.hasEnded.withLock { $0 = true }
            return answer
        }
        self.task = task
        let deadline = ContinuousClock.now + firstFrameLimit
        while output.recording.withLock({ $0.frames.isEmpty }) {
            if output.hasEnded.withLock({ $0 }) {
                let answer = await task.value
                await discard()
                throw answer.isFromOlderHelper ? Failure.olderHelper : Failure.didntStart(answer.failure)
            }
            if ContinuousClock.now >= deadline {
                await discard()
                throw Failure.didntStart(String(localized: "no frame came in time"))
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Stops recording, reads when the test in `resultBundle` took each of
    /// its screenshots, and returns the frame kept for each, oldest first;
    /// the recording is then deleted.
    func finish(resultBundle: String) async throws -> [Shot] {
        guard let task, let output, let simulators else { throw Failure.notRecording }
        task.cancel()
        _ = await task.value
        let recording = output.recording.withLock { $0 }
        do {
            let shots = try await shots(in: resultBundle, recording: recording, simulators: simulators)
            await discard()
            return shots
        } catch {
            await discard()
            throw error
        }
    }

    /// Stops the recording, if one is going, and deletes its frames.
    func discard() async {
        task?.cancel()
        _ = await task?.value
        task = nil
        let folder = output?.recording.withLock { $0.folder }
        output = nil
        if let folder, let simulators { _ = await simulators.run(["discard-recording", folder]) }
    }

    // MARK: - The test's screenshots

    private func shots(in bundle: String, recording: DisplayRecording, simulators: MacSimulators) async throws -> [Shot] {
        let tests = await simulators.run(["test-results", bundle])
        guard tests.succeeded else {
            throw tests.isFromOlderHelper ? Failure.olderHelper : Failure.unreadableResults(tests.failure)
        }
        var screenshots: [TestScreenshot] = []
        for test in XcresultTimeline.testIDs(in: Self.data(tests)) {
            let activities = await simulators.run(["test-results", bundle, test])
            guard activities.succeeded else { throw Failure.unreadableResults(activities.failure) }
            screenshots += XcresultTimeline.screenshots(in: Self.data(activities))
        }
        let recorded = screenshots.filter { $0.deviceID == nil || $0.deviceID == udid }
        var shots: [Shot] = []
        for pick in RecordedFramePick.picks(for: recorded, in: recording.frames) {
            await shots.append(Shot(pick: pick, png: png(of: pick.frame, in: recording, simulators: simulators)))
        }
        shots += screenshots.filter { !recorded.contains($0) }.map {
            Shot(pick: RecordedFramePick(screenshot: $0), png: nil, isOnOtherSimulator: true)
        }
        return shots.sorted { $0.pick.screenshot.time < $1.pick.screenshot.time }
    }

    private func png(of frame: RecordedFrame?, in recording: DisplayRecording, simulators: MacSimulators) async -> Data? {
        guard let frame, let path = recording.path(of: frame) else { return nil }
        let answer = await simulators.run(["recorded-frame", path])
        guard answer.succeeded else { return nil }
        return Data(base64Encoded: answer.lines.joined())
    }

    private static func data(_ answer: SimulatorHelperAnswer) -> Data {
        Data(answer.lines.joined(separator: "\n").utf8)
    }
}
