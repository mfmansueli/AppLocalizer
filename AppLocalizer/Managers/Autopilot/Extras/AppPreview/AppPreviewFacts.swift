//
//  AppPreviewFacts.swift
//  AppLocalizer
//

import Foundation

/// What an App Preview file turned out to be, read back from the file, and
/// where it breaks Apple's rules for its device.
struct AppPreviewFacts: Hashable, Sendable {
    var seconds: Double
    /// As displayed, after the track's rotation.
    var pixelSize: PixelSize
    var framesPerSecond: Double
    var codec: Codec
    /// The sound track's channels; 0 without one.
    var audioChannels: Int
    var byteCount: Int64

    /// The video codecs App Store Connect takes for an App Preview, and
    /// anything else.
    enum Codec: String, Hashable, Sendable {
        case h264
        case proRes422HQ
        case other
    }

    /// Rounding the file's timing may leave.
    static let secondsTolerance = 0.05

    /// One plain sentence per rule the file breaks; empty when it's ready
    /// for App Store Connect. Either orientation of the spec's size counts.
    func issues(against spec: AppPreviewSpec) -> [String] {
        var issues: [String] = []
        let length = seconds.formatted(.number.precision(.fractionLength(1)))
        if seconds < spec.minimumSeconds - Self.secondsTolerance || seconds > spec.maximumSeconds + Self.secondsTolerance {
            let minimum = Int(spec.minimumSeconds)
            let maximum = Int(spec.maximumSeconds)
            issues.append(String(localized: "The App Preview is \(length) seconds long; App Store Connect takes \(minimum) to \(maximum) seconds."))
        }
        if framesPerSecond > Double(spec.framesPerSecond) + 0.5 {
            let rate = framesPerSecond.formatted(.number.precision(.fractionLength(0...1)))
            issues.append(String(localized: "The App Preview plays at \(rate) frames a second; App Store Connect takes at most \(spec.framesPerSecond)."))
        }
        if pixelSize != spec.pixelSize, pixelSize != spec.pixelSize.rotated {
            let display = spec.displayType.title
            issues.append(String(localized: "The App Preview is \(pixelSize.title) pixels; \(display) takes \(spec.pixelSize.title) or \(spec.pixelSize.rotated.title)."))
        }
        if codec == .other {
            issues.append(String(localized: "The App Preview isn't H.264 or ProRes 422 HQ, the only video App Store Connect takes."))
        }
        if audioChannels == 0 {
            issues.append(String(localized: "The App Preview has no sound track; App Store Connect wants a stereo one, even a silent one."))
        } else if audioChannels == 1 {
            issues.append(String(localized: "The App Preview's sound is mono; App Store Connect wants stereo."))
        } else if audioChannels != 2 {
            issues.append(String(localized: "The App Preview's sound has \(audioChannels) channels; App Store Connect wants stereo."))
        }
        if byteCount > spec.maximumBytes {
            let size = ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
            let limit = ByteCountFormatter.string(fromByteCount: spec.maximumBytes, countStyle: .file)
            issues.append(String(localized: "The App Preview is \(size), more than App Store Connect's \(limit)."))
        }
        return issues
    }
}
