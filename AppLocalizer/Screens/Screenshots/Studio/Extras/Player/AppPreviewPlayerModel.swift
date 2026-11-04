//
//  AppPreviewPlayerModel.swift
//  AppLocalizer
//

import AVFoundation
import Foundation
import Observation

/// Plays one App Preview file: play and pause, where it is, sound on or
/// off, and jumping to a scene. Back at the start when it ends, or on
/// again from the start when it `loops` (a motion header or search image).
@MainActor
@Observable
final class AppPreviewPlayerModel {
    private(set) var url: URL?
    private(set) var isPlaying = false
    private(set) var seconds = 0.0
    private(set) var duration = 0.0
    var isMuted = false {
        didSet { player.isMuted = isMuted }
    }

    /// Plays again from the start when it ends, as the App Store plays a
    /// motion loop.
    var loops = false

    /// There's a file that plays: false while there's none, or when it
    /// can't be read (the poster shows instead).
    private(set) var canPlay = false

    @ObservationIgnored let player = AVPlayer()
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: (any NSObjectProtocol)?
    @ObservationIgnored private var statusObservation: NSKeyValueObservation?
    /// It was playing when a drag on the scrubber began.
    @ObservationIgnored private var resumesAfterScrub = false

    init() {
        player.actionAtItemEnd = .pause
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 10), queue: .main) { [weak self] time in
            MainActor.assumeIsolated { self?.seconds = max(0, time.seconds.isFinite ? time.seconds : 0) }
        }
    }

    isolated deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        statusObservation?.invalidate()
    }

    /// Loads `url` from the start, paused; the same file stays where it is.
    /// `seconds` is its length when known; 0 reads it from the file.
    func load(_ url: URL?, seconds length: Double) {
        guard url != self.url else { return }
        self.url = url
        pause()
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        statusObservation = nil
        seconds = 0
        duration = length
        guard let url, FileManager.default.fileExists(atPath: url.path) else {
            canPlay = false
            player.replaceCurrentItem(with: nil)
            return
        }
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        canPlay = true
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor in self?.didFail(url) }
        }
        endObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.didEnd() }
        }
        if length <= 0 {
            Task { [weak self] in
                guard let time = try? await item.asset.load(.duration), time.seconds.isFinite, let self, self.url == url else { return }
                duration = time.seconds
            }
        }
    }

    func play() {
        guard canPlay else { return }
        if duration > 0, seconds >= duration - 0.05 { seek(to: 0) }
        player.play()
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func toggle() {
        if isPlaying { pause() } else { play() }
    }

    /// A drag on the scrubber pauses it until the drag ends.
    func scrub(_ active: Bool) {
        if active {
            resumesAfterScrub = isPlaying
            pause()
        } else if resumesAfterScrub {
            resumesAfterScrub = false
            play()
        }
    }

    func seek(to time: Double) {
        let time = min(max(0, time), max(duration, 0))
        seconds = time
        player.seek(to: CMTime(seconds: time, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// The file isn't a movie AVFoundation plays.
    private func didFail(_ failed: URL) {
        guard url == failed else { return }
        pause()
        canPlay = false
        player.replaceCurrentItem(with: nil)
    }

    private func didEnd() {
        seek(to: 0)
        if loops, isPlaying {
            player.play()
        } else {
            isPlaying = false
        }
    }

    /// "0:08 / 0:24".
    var timeTitle: String {
        "\(ExtrasPreviewFile.lengthTitle(seconds.rounded(.down))) / \(ExtrasPreviewFile.lengthTitle(duration))"
    }
}
