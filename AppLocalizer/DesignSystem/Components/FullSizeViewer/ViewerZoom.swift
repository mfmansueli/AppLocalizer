//
//  ViewerZoom.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// How far a full-size viewer is zoomed in and where it's moved to: a
/// pinch keeps the point between the fingers in place, a pan never moves
/// the content past its edges, and 1× is always centred. Points are
/// relative to the frame's center.
struct ViewerZoom: Hashable {
    static let maximumScale: CGFloat = 8
    /// What a double-click zooms to from fit.
    static let doubleClickScale: CGFloat = 2

    var scale: CGFloat = 1
    var offset: CGSize = .zero

    static let fit = ViewerZoom()

    var isZoomed: Bool { scale > 1.001 }

    /// "250%".
    var percentTitle: String { "\(Int((scale * 100).rounded()))%" }

    /// `self` pinched by `magnification` around `anchor`, in a frame
    /// `size`. Called with the zoom from when the pinch began.
    func pinched(by magnification: CGFloat, around anchor: CGPoint, in size: CGSize) -> ViewerZoom {
        let newScale = min(max(scale * magnification, 1), Self.maximumScale)
        let ratio = newScale / scale
        let moved = CGSize(
            width: anchor.x * (1 - ratio) + offset.width * ratio,
            height: anchor.y * (1 - ratio) + offset.height * ratio
        )
        return ViewerZoom(scale: newScale, offset: moved).clamped(in: size)
    }

    /// `self` moved by `translation`, in a frame `size`.
    func panned(by translation: CGSize, in size: CGSize) -> ViewerZoom {
        ViewerZoom(scale: scale, offset: CGSize(width: offset.width + translation.width, height: offset.height + translation.height))
            .clamped(in: size)
    }

    /// A double-click: back to fit when zoomed, else 2× around `anchor`.
    func toggled(around anchor: CGPoint, in size: CGSize) -> ViewerZoom {
        isZoomed ? .fit : pinched(by: Self.doubleClickScale / scale, around: anchor, in: size)
    }

    /// The offset kept within what the zoom lets it reach: at `scale`, the
    /// content is `scale - 1` frames bigger, half on each side.
    func clamped(in size: CGSize) -> ViewerZoom {
        guard isZoomed else { return .fit }
        let reach = CGSize(width: (scale - 1) * size.width / 2, height: (scale - 1) * size.height / 2)
        return ViewerZoom(scale: scale, offset: CGSize(
            width: min(max(offset.width, -reach.width), reach.width),
            height: min(max(offset.height, -reach.height), reach.height)
        ))
    }
}
