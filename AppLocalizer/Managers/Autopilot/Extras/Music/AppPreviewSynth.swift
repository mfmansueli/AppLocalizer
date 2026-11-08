//
//  AppPreviewSynth.swift
//  AppLocalizer
//

import Foundation

/// AppLocalizer's music library, played on this Mac: each track is a short
/// loop of chords written here and synthesized note by note (plucked
/// strings, a soft piano, a synth arpeggio with bass and light drums), so
/// it belongs to no one else and can go on the App Store. The same track
/// and length always sound the same. Interleaved stereo at 44.1 kHz,
/// peaking just under full scale; `AppPreviewSoundtrack` fades and levels
/// it.
enum AppPreviewSynth {
    static let sampleRate = 44100.0

    /// `seconds` of `track`; nothing for the person's own file.
    static func render(_ track: AppPreviewTrack, seconds: Double) -> [Float] {
        let frames = max(0, Int((seconds * sampleRate).rounded()))
        var mix = Mix(frames: frames)
        switch track {
        case .warmAcoustic: warmAcoustic(into: &mix)
        case .calmPiano: calmPiano(into: &mix)
        case .brightPop: brightPop(into: &mix)
        case .softAmbient: softAmbient(into: &mix)
        case .lofiBeat: lofiBeat(into: &mix)
        case .cinematicBuild: cinematicBuild(into: &mix)
        case .playfulMarimba: playfulMarimba(into: &mix)
        case .ownFile: return []
        }
        return mix.finished()
    }

    // MARK: - Tracks

    /// G – D – Em – C at 92 bpm: eighth-note arpeggios on plucked strings
    /// over a soft bass on beats one and three.
    private static func warmAcoustic(into mix: inout Mix) {
        let beat = 60.0 / 92
        let chords: [[Int]] = [[55, 59, 62], [50, 54, 57], [52, 55, 59], [48, 52, 55]]
        let pattern = [0, 1, 2, 3, 4, 3, 2, 1]
        var bar = 0
        while Double(bar) * 4 * beat < mix.seconds {
            let chord = chords[bar % chords.count]
            let voices = chord + chord.map { $0 + 12 }
            let start = Double(bar) * 4 * beat
            for (step, index) in pattern.enumerated() {
                let note = voices[min(index + 1, voices.count - 1)]
                let pan = step.isMultiple(of: 2) ? -0.35 : 0.35
                mix.pluck(midi: note, at: start + Double(step) * beat / 2, length: beat * 3, amplitude: 0.32, pan: pan)
            }
            for beatIndex in [0, 2] {
                mix.tone(
                    midi: chord[0] - 12, at: start + Double(beatIndex) * beat, length: beat * 1.8, amplitude: 0.42,
                    timbre: Timbre(harmonics: [1, 0.35, 0.1], decay: 0.9), pan: 0
                )
            }
            bar += 1
        }
        mix.echo(left: 0.19, right: 0.27, feedback: 0.28, wet: 0.22)
        mix.room(seconds: 1.2, wet: 0.14)
    }

    /// C – Am – F – G at 70 bpm: block chords on a soft piano, a few high
    /// notes between them, the root low under each bar.
    private static func calmPiano(into mix: inout Mix) {
        let beat = 60.0 / 70
        let chords: [[Int]] = [[60, 64, 67, 72], [57, 60, 64, 69], [53, 57, 60, 65], [55, 59, 62, 67]]
        let melody = [[76, 74, 72], [72, 71, 69], [69, 72, 77], [74, 71, 67]]
        let piano: [Float] = [1, 0.42, 0.18, 0.08, 0.04]
        var bar = 0
        while Double(bar) * 4 * beat < mix.seconds {
            let chord = chords[bar % chords.count]
            let start = Double(bar) * 4 * beat
            for (index, note) in chord.enumerated() {
                mix.tone(
                    midi: note, at: start + Double(index) * 0.012, length: beat * 4, amplitude: 0.2, timbre: Timbre(harmonics: piano, decay: 1.6),
                    pan: Double(index) * 0.2 - 0.3
                )
            }
            mix.tone(midi: chord[0] - 12, at: start, length: beat * 4, amplitude: 0.3, timbre: Timbre(harmonics: piano, decay: 2.2), pan: -0.15)
            for (index, note) in melody[bar % melody.count].enumerated() {
                mix.tone(
                    midi: note, at: start + Double(index + 1) * beat, length: beat * 2, amplitude: 0.16,
                    timbre: Timbre(harmonics: piano, decay: 1.1), pan: 0.3
                )
            }
            bar += 1
        }
        mix.echo(left: 0.23, right: 0.31, feedback: 0.35, wet: 0.3)
        mix.room(seconds: 2, wet: 0.2)
    }

    /// D – A – Bm – G at 118 bpm: a sixteenth-note synth arpeggio, eighth
    /// notes of bass, a kick on every beat and a hi-hat between.
    private static func brightPop(into mix: inout Mix) {
        let beat = 60.0 / 118
        let chords: [[Int]] = [[62, 66, 69], [57, 61, 64], [59, 62, 66], [55, 59, 62]]
        let lead: [Float] = [1, 0, 0.33, 0, 0.2]
        var bar = 0
        while Double(bar) * 4 * beat < mix.seconds {
            let chord = chords[bar % chords.count]
            let voices = chord + chord.map { $0 + 12 }
            let start = Double(bar) * 4 * beat
            for step in 0..<16 {
                let note = voices[[0, 2, 4, 3, 1, 3, 5, 4][step % 8]]
                mix.tone(
                    midi: note, at: start + Double(step) * beat / 4, length: beat / 4 * 0.9, amplitude: 0.12, timbre: Timbre(harmonics: lead, decay: 0.12),
                    pan: step.isMultiple(of: 2) ? -0.4 : 0.4
                )
            }
            for step in 0..<8 {
                mix.tone(
                    midi: chord[0] - 24, at: start + Double(step) * beat / 2, length: beat / 2 * 0.85, amplitude: 0.34,
                    timbre: Timbre(harmonics: [1, 0.5, 0.25], decay: 0.25), pan: 0
                )
            }
            for beatIndex in 0..<4 {
                let time = start + Double(beatIndex) * beat
                mix.kick(at: time, amplitude: 0.55)
                mix.hat(at: time + beat / 2, amplitude: 0.09, pan: 0.25)
            }
            bar += 1
        }
        mix.echo(left: 0.127, right: 0.19, feedback: 0.2, wet: 0.14)
        mix.room(seconds: 0.9, wet: 0.1)
    }

    // MARK: - The mix

    /// Two channels being written, note by note.
    /// A tone's sound: a few harmonics (`harmonics[i]` is the (i + 1)th's
    /// level) and an exponential decay of `decay` seconds.
    struct Timbre {
        var harmonics: [Float]
        var decay: Double
        /// Seconds to full level, and to silence at the end of the note.
        var attack = 0.006
        var release = 0.04
        /// Off pitch by this many cents: two a little apart sound wide.
        var detune = 0.0
    }

    struct Mix {
        var left: [Float]
        var right: [Float]
        private var random = Noise(seed: 0x9E37_79B9)

        init(frames: Int) {
            left = [Float](repeating: 0, count: frames)
            right = [Float](repeating: 0, count: frames)
        }

        var frames: Int { left.count }
        var seconds: Double { Double(frames) / AppPreviewSynth.sampleRate }

        static func frequency(midi: Int) -> Double {
            440 * pow(2, Double(midi - 69) / 12)
        }

        /// Left and right gains for a pan from −1 (left) to 1 (right).
        static func gains(pan: Double) -> (Float, Float) {
            let angle = (min(max(pan, -1), 1) + 1) * .pi / 4
            return (Float(cos(angle)), Float(sin(angle)))
        }

        /// A plucked string (Karplus–Strong): a burst of noise ringing in a
        /// delay line as long as the note's period, softened as it rings.
        mutating func pluck(midi: Int, at start: Double, length: Double, amplitude: Float, pan: Double) {
            let first = Int(start * AppPreviewSynth.sampleRate)
            guard first < frames else { return }
            let count = min(Int(length * AppPreviewSynth.sampleRate), frames - first)
            let period = max(2, Int(AppPreviewSynth.sampleRate / Self.frequency(midi: midi)))
            var line = (0..<period).map { _ in random.next() }
            for index in 1..<period { line[index] = 0.5 * (line[index] + line[index - 1]) }
            let (gainL, gainR) = Self.gains(pan: pan)
            let release = min(count, Int(0.05 * AppPreviewSynth.sampleRate))
            var position = 0
            left.withUnsafeMutableBufferPointer { left in
                right.withUnsafeMutableBufferPointer { right in
                    for offset in 0..<count {
                        let next = position + 1 == period ? 0 : position + 1
                        let sample = line[position]
                        line[position] = 0.996 * 0.5 * (line[position] + line[next])
                        position = next
                        let fade: Float = offset >= count - release ? Float(count - offset) / Float(max(release, 1)) : 1
                        let value = sample * amplitude * fade
                        left[first + offset] += value * gainL
                        right[first + offset] += value * gainR
                    }
                }
            }
        }

        /// A note in `timbre`, with a quick attack; sines by recurrence, so
        /// no sine per sample.
        mutating func tone(midi: Int, at start: Double, length: Double, amplitude: Float, timbre: Timbre, pan: Double) {
            let (harmonics, decay) = (timbre.harmonics, timbre.decay)
            let first = Int(start * AppPreviewSynth.sampleRate)
            guard first < frames else { return }
            let count = min(Int(length * AppPreviewSynth.sampleRate), frames - first)
            let base = Self.frequency(midi: midi) * pow(2, timbre.detune / 1200)
            let (gainL, gainR) = Self.gains(pan: pan)
            let attack = max(1, Int(timbre.attack * AppPreviewSynth.sampleRate))
            let release = min(count, Int(timbre.release * AppPreviewSynth.sampleRate))
            let fall = Float(exp(-1 / (decay * AppPreviewSynth.sampleRate)))
            for (index, level) in harmonics.enumerated() where level > 0 {
                let omega = 2 * Double.pi * base * Double(index + 1) / AppPreviewSynth.sampleRate
                guard omega < .pi * 0.9 else { continue }
                let coefficient = Float(2 * cos(omega))
                var previous = Float(-sin(omega))
                var beforePrevious = Float(-sin(2 * omega))
                var envelope: Float = 1
                left.withUnsafeMutableBufferPointer { left in
                    right.withUnsafeMutableBufferPointer { right in
                        for offset in 0..<count {
                            let sine = coefficient * previous - beforePrevious
                            beforePrevious = previous
                            previous = sine
                            envelope *= fall
                            var shape = envelope
                            if offset < attack { shape *= Float(offset) / Float(attack) }
                            if offset >= count - release { shape *= Float(count - offset) / Float(max(release, 1)) }
                            let value = sine * level * amplitude * shape
                            left[first + offset] += value * gainL
                            right[first + offset] += value * gainR
                        }
                    }
                }
            }
        }

        /// A kick: a sine falling from 120 Hz to 48 Hz in a quarter second.
        mutating func kick(at start: Double, amplitude: Float) {
            let first = Int(start * AppPreviewSynth.sampleRate)
            guard first < frames else { return }
            let count = min(Int(0.25 * AppPreviewSynth.sampleRate), frames - first)
            var phase = 0.0
            for offset in 0..<count {
                let time = Double(offset) / AppPreviewSynth.sampleRate
                phase += 2 * .pi * (48 + 72 * exp(-time * 28)) / AppPreviewSynth.sampleRate
                let value = Float(sin(phase) * exp(-time * 14)) * amplitude
                left[first + offset] += value * 0.7
                right[first + offset] += value * 0.7
            }
        }

        /// A closed hi-hat: bright noise fading in 40 ms.
        mutating func hat(at start: Double, amplitude: Float, pan: Double) {
            let first = Int(start * AppPreviewSynth.sampleRate)
            guard first < frames else { return }
            let count = min(Int(0.04 * AppPreviewSynth.sampleRate), frames - first)
            let (gainL, gainR) = Self.gains(pan: pan)
            var last: Float = 0
            for offset in 0..<count {
                let noise = random.next()
                let bright = noise - last
                last = noise
                let value = bright * amplitude * Float(1 - Double(offset) / Double(count))
                left[first + offset] += value * gainL
                right[first + offset] += value * gainR
            }
        }

        /// A snare: a burst of noise over a short 190 Hz thump.
        mutating func snare(at start: Double, amplitude: Float) {
            let first = Int(start * AppPreviewSynth.sampleRate)
            guard first < frames else { return }
            let count = min(Int(0.16 * AppPreviewSynth.sampleRate), frames - first)
            for offset in 0..<count {
                let time = Double(offset) / AppPreviewSynth.sampleRate
                let body = Float(sin(2 * .pi * 190 * time) * exp(-time * 40)) * 0.6
                let value = (random.next() * Float(exp(-time * 24)) + body) * amplitude
                left[first + offset] += value
                right[first + offset] += value
            }
        }

        /// A ping-pong echo for a little room: each side hears the other a
        /// moment later.
        mutating func echo(left delayLeft: Double, right delayRight: Double, feedback: Float, wet: Float) {
            let lagL = Int(delayLeft * AppPreviewSynth.sampleRate)
            let lagR = Int(delayRight * AppPreviewSynth.sampleRate)
            guard frames > max(lagL, lagR) else { return }
            var echoL = [Float](repeating: 0, count: frames)
            var echoR = [Float](repeating: 0, count: frames)
            for index in 0..<frames {
                if index >= lagL { echoL[index] = (right[index - lagL] + echoR[index - lagL]) * feedback }
                if index >= lagR { echoR[index] = (left[index - lagR] + echoL[index - lagR]) * feedback }
            }
            for index in 0..<frames {
                left[index] += echoL[index] * wet / max(feedback, 0.01)
                right[index] += echoR[index] * wet / max(feedback, 0.01)
            }
        }

        /// A room around the sound (four comb filters and two all-passes a
        /// side, the sides a little apart): `seconds` is how long it rings.
        mutating func room(seconds: Double, wet: Float) {
            let wetLeft = Self.reverberated(left, spread: 0, seconds: seconds)
            let wetRight = Self.reverberated(right, spread: 23, seconds: seconds)
            for index in 0..<frames {
                left[index] += wetLeft[index] * wet
                right[index] += wetRight[index] * wet
            }
        }

        private static func reverberated(_ dry: [Float], spread: Int, seconds: Double) -> [Float] {
            var out = [Float](repeating: 0, count: dry.count)
            for delay in [1557, 1617, 1491, 1422].map({ $0 + spread }) {
                let feedback = Float(pow(10, -3 * Double(delay) / AppPreviewSynth.sampleRate / max(seconds, 0.05)))
                var line = dry
                for index in delay..<max(delay, dry.count) { line[index] += line[index - delay] * feedback }
                for index in dry.indices { out[index] += (line[index] - dry[index]) * 0.25 }
            }
            for delay in [225, 556].map({ $0 + spread }) {
                let input = out
                for index in dry.indices {
                    let earlierIn = index >= delay ? input[index - delay] : 0
                    let earlierOut = index >= delay ? out[index - delay] : 0
                    out[index] = -0.5 * input[index] + earlierIn + 0.5 * earlierOut
                }
            }
            return out
        }

        /// Interleaved, peaking at 0.95.
        func finished() -> [Float] {
            var peak: Float = 0
            for index in 0..<frames { peak = max(peak, abs(left[index]), abs(right[index])) }
            let scale = peak > 0 ? 0.95 / peak : 0
            var out = [Float](repeating: 0, count: frames * 2)
            for index in 0..<frames {
                out[index * 2] = left[index] * scale
                out[index * 2 + 1] = right[index] * scale
            }
            return out
        }
    }

    /// The same noise every time: xorshift, −1…1.
    private struct Noise {
        var state: UInt32

        init(seed: UInt32) { state = seed == 0 ? 1 : seed }

        mutating func next() -> Float {
            state ^= state << 13
            state ^= state >> 17
            state ^= state << 5
            return Float(state) / Float(UInt32.max) * 2 - 1
        }
    }
}
