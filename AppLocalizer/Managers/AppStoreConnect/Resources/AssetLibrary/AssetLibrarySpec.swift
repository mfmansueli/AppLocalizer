//
//  AssetLibrarySpec.swift
//  AppLocalizer
//

import Foundation

/// One of Apple's image or video specifications from the asset library's
/// reference data, e.g. `i3840x1646a0`: the sizes it accepts and the
/// placement types it's for.
struct AssetLibrarySpec: Hashable, Sendable {
    /// Apple's `specId`, which placement types' spec mappings refer to.
    var id: String
    var shortName: String?
    var media: AssetLibraryMedia
    var minWidth: Int?
    var maxWidth: Int?
    var minHeight: Int?
    var maxHeight: Int?
    /// Apple's `aspectRatio` as width ÷ height, e.g. 1.5 for "3:2". A spec
    /// with a range of sizes takes only those of this shape.
    var aspectRatio: Double?
    var compatiblePlacementTypes: [String] = []
    /// In bytes.
    var maxFileSize: Int?
    /// One asset that serves every platform, e.g. the 16:9 header.
    var isUniversal = false

    /// How far a size's shape may be from `aspectRatio`: 886 × 1920 is
    /// Apple's "6:13" though not exactly.
    static let aspectTolerance = 0.01

    /// Whether a file of `size` meets it. A spec that gives no width or no
    /// height accepts nothing, since there's no way to tell.
    func accepts(_ size: PixelSize) -> Bool {
        guard minWidth != nil || maxWidth != nil, minHeight != nil || maxHeight != nil else { return false }
        let width = (minWidth ?? 0)...max(minWidth ?? 0, maxWidth ?? .max)
        let height = (minHeight ?? 0)...max(minHeight ?? 0, maxHeight ?? .max)
        guard width.contains(size.width), height.contains(size.height) else { return false }
        guard let aspectRatio, aspectRatio > 0, size.height > 0 else { return true }
        return abs(Double(size.width) / Double(size.height) - aspectRatio) / aspectRatio <= Self.aspectTolerance
    }

    /// "3:2" as 1.5; nil when it isn't two positive numbers.
    static func ratio(_ text: String?) -> Double? {
        let parts = (text ?? "").split(separator: ":").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2, parts[0] > 0, parts[1] > 0 else { return nil }
        return parts[0] / parts[1]
    }

    /// The one size it takes, when its minimum and maximum agree.
    var exactSize: PixelSize? {
        guard let minWidth, let minHeight, maxWidth == minWidth, maxHeight == minHeight else { return nil }
        return PixelSize(width: minWidth, height: minHeight)
    }
}
