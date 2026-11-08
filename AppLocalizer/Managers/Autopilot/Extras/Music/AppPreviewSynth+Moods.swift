//
//  AppPreviewSynth+Moods.swift
//  AppLocalizer
//

import Foundation

/// The library's other moods, so a track can suit the app: a slow wash, a
/// mellow beat, a build and something playful. Each changes as it goes
/// instead of repeating four bars.
extension AppPreviewSynth {
    /// Am – F – C – G at 64 bpm: long detuned pads that fade into each
    /// other, a low drone, and a few bell notes.
    static func softAmbient(into mix: inout Mix) {
        let bar = 60.0 / 64 * 4
        let chords: [[Int]] = [[57, 64, 67, 71], [53, 60, 64, 69], [48, 55, 60, 64], [55, 59, 62, 69]]
        let bells: [[Int]] = [[76, 79], [72], [79, 84], [74, 71]]
        var index = 0
        while Double(index) * bar < mix.seconds {
            let start = Double(index) * bar
            let chord = chords[index % chords.count]
            for (voice, note) in chord.enumerated() {
                for detune in [-6.0, 6.0] {
                    let pad = Timbre(harmonics: [1, 0.4, 0.15, 0.05], decay: 40, attack: 1.3, release: 1.6, detune: detune)
                    mix.tone(midi: note, at: start, length: bar + 1.6, amplitude: 0.09, timbre: pad, pan: Double(voice) * 0.25 - 0.4 + detune / 30)
                }
            }
            let drone = Timbre(harmonics: [1, 0.2], decay: 40, attack: 1.5, release: 1.5)
            mix.tone(midi: chord[0] - 12, at: start, length: bar + 1.5, amplitude: 0.2, timbre: drone, pan: 0)
            // The bells come in after the first two bars.
            if index >= 2 {
                for (step, note) in bells[index % bells.count].enumerated() {
                    let bell = Timbre(harmonics: [1, 0, 0.3, 0, 0.12], decay: 1.6, attack: 0.004, release: 0.4)
                    mix.tone(
                        midi: note, at: start + bar * (0.25 + Double(step) * 0.4), length: 3, amplitude: 0.1, timbre: bell,
                        pan: step.isMultiple(of: 2) ? 0.35 : -0.35
                    )
                }
            }
            index += 1
        }
        mix.room(seconds: 3.2, wet: 0.4)
    }

    /// Dm9 – G13 – Cmaj9 – Am9 at 76 bpm: soft electric keys, a round bass
    /// and a laid-back beat with swung hats; the hats join after two bars.
    static func lofiBeat(into mix: inout Mix) {
        let beat = 60.0 / 76
        let chords: [[Int]] = [[62, 65, 69, 72, 76], [55, 65, 69, 71, 76], [60, 64, 67, 71, 74], [57, 60, 64, 67, 71]]
        let keys = Timbre(harmonics: [1, 0.5, 0.08, 0.2, 0.04], decay: 1, attack: 0.012, release: 0.15)
        let bass = Timbre(harmonics: [1, 0.3, 0.05], decay: 0.7, attack: 0.01, release: 0.08)
        var bar = 0
        while Double(bar) * 4 * beat < mix.seconds {
            let start = Double(bar) * 4 * beat
            let chord = chords[bar % chords.count]
            for hit in bar.isMultiple(of: 2) ? [0.0, 2.5] : [0.0, 1.5, 3.0] {
                for (voice, note) in chord.enumerated() {
                    mix.tone(
                        midi: note, at: start + hit * beat + Double(voice) * 0.01, length: beat * 1.4, amplitude: 0.11, timbre: keys,
                        pan: Double(voice) * 0.15 - 0.3
                    )
                }
            }
            for hit in [0.0, 1.5, 2.5] {
                mix.tone(midi: chord[0] - 24, at: start + hit * beat, length: beat, amplitude: 0.36, timbre: bass, pan: 0)
            }
            for hit in [0.0, 2.25] { mix.kick(at: start + hit * beat, amplitude: 0.5) }
            for hit in [1.0, 3.0] { mix.snare(at: start + hit * beat, amplitude: 0.2) }
            if bar >= 2 {
                for step in 0..<8 {
                    let swing = step.isMultiple(of: 2) ? 0 : beat * 0.08
                    mix.hat(at: start + Double(step) * beat / 2 + swing, amplitude: step.isMultiple(of: 2) ? 0.07 : 0.04, pan: 0.2)
                }
            }
            bar += 1
        }
        mix.room(seconds: 1.1, wet: 0.16)
    }

    /// Am – F – C – G at 88 bpm: strings that swell over the whole length,
    /// a plucked pulse from the second bar and low hits in the second half.
    static func cinematicBuild(into mix: inout Mix) {
        let beat = 60.0 / 88
        let chords: [[Int]] = [[57, 60, 64, 69], [53, 57, 60, 65], [48, 55, 60, 64], [55, 59, 62, 67]]
        var bar = 0
        while Double(bar) * 4 * beat < mix.seconds {
            let start = Double(bar) * 4 * beat
            let chord = chords[bar % chords.count]
            let grown = Float(min(1, start / max(mix.seconds, 1)))
            for (voice, note) in chord.enumerated() {
                for detune in [-5.0, 5.0] {
                    let strings = Timbre(harmonics: [1, 0.6, 0.35, 0.2, 0.1], decay: 40, attack: 0.5, release: 0.8, detune: detune)
                    mix.tone(
                        midi: note - 12, at: start, length: beat * 4 + 0.8, amplitude: 0.05 + 0.07 * grown, timbre: strings,
                        pan: Double(voice) * 0.3 - 0.45
                    )
                }
            }
            if bar >= 1 {
                for step in 0..<8 {
                    let note = chord[[0, 2, 1, 3][step % 4]] + 12
                    mix.pluck(
                        midi: note, at: start + Double(step) * beat / 2, length: beat, amplitude: 0.12 + 0.14 * grown,
                        pan: step.isMultiple(of: 2) ? -0.3 : 0.3
                    )
                }
            }
            if start >= mix.seconds / 2 {
                for hit in [0.0, 2.0] { mix.kick(at: start + hit * beat, amplitude: 0.35 + 0.3 * grown) }
            }
            bar += 1
        }
        mix.room(seconds: 2.4, wet: 0.3)
    }

    /// F – C – Dm – Bb at 124 bpm: a bouncing marimba line, plucked bass
    /// and light claps from the third bar.
    static func playfulMarimba(into mix: inout Mix) {
        let beat = 60.0 / 124
        let chords: [[Int]] = [[65, 69, 72], [60, 64, 67], [62, 65, 69], [58, 62, 65]]
        let marimba = Timbre(harmonics: [1, 0, 0, 0.35], decay: 0.2, attack: 0.002, release: 0.06)
        let lines = [[0, 3, 6, 8, 11, 14], [0, 2, 6, 10, 12, 15]]
        var bar = 0
        while Double(bar) * 4 * beat < mix.seconds {
            let start = Double(bar) * 4 * beat
            let chord = chords[bar % chords.count]
            let voices = chord + chord.map { $0 + 12 }
            for (index, step) in lines[bar % lines.count].enumerated() {
                let note = voices[(index * 2 + bar) % voices.count]
                mix.tone(
                    midi: note, at: start + Double(step) * beat / 4, length: beat, amplitude: 0.26, timbre: marimba,
                    pan: index.isMultiple(of: 2) ? -0.35 : 0.35
                )
            }
            for hit in [0, 2] {
                mix.pluck(midi: chord[0] - 24, at: start + Double(hit) * beat, length: beat * 1.5, amplitude: 0.5, pan: 0)
            }
            if bar >= 2 {
                for hit in [1, 3] { mix.snare(at: start + Double(hit) * beat, amplitude: 0.1) }
            }
            bar += 1
        }
        mix.room(seconds: 0.9, wet: 0.14)
    }
}
