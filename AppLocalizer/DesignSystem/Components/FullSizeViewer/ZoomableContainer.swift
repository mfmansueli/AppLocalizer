//
//  ZoomableContainer.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// Zooms what it holds with the trackpad, the way Preview does: pinch to
/// zoom in and out (1× to 8×, around the fingers), two-finger scroll or
/// drag to move around once zoomed, and double-click for 2× or back to fit
/// (`doubleClickZooms`, off where a click plays a movie). While zoomed,
/// "250%" and Fit sit in the bottom corner. Clipped to its frame; the zoom
/// starts at fit again when the container is made again (another item).
///
/// At fit only what it draws takes the pinch, so a click beside it still
/// reaches what's behind (the viewer closes); zoomed, all of its frame
/// does.
struct ZoomableContainer<Content: View>: View {
    /// `review.viewer.zoom`: the percentage and Fit get `.percent` and
    /// `.fit`.
    let identifier: String
    var doubleClickZooms = true
    /// What it shows, when it's the viewer's whole item ("English (U.S.) ·
    /// Header 21:9"); a wrapper's own label would replace its identifier.
    var label: String?
    @ViewBuilder let content: () -> Content

    @State private var zoom = ViewerZoom.fit
    @State private var pinchStart: ViewerZoom?
    @State private var panStart: ViewerZoom?
    @State private var frameSize = CGSize.zero
    @State private var isHovering = false
    @State private var scrollMonitor = ScrollMonitor()

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            content()
                .frame(width: size.width, height: size.height)
                .scaleEffect(zoom.scale)
                .offset(zoom.offset)
                .frame(width: size.width, height: size.height)
                .background {
                    if zoom.isZoomed { Color.clear.contentShape(Rectangle()) }
                }
                .gesture(magnify(in: size))
                .simultaneousGesture(pan(in: size), including: zoom.isZoomed ? .all : .subviews)
                .simultaneousGesture(doubleClick(in: size), including: doubleClickZooms ? .all : .subviews)
                .onContinuousHover { phase in
                    if case .active = phase { isHovering = true } else { isHovering = false }
                }
                .onChange(of: size, initial: true) { frameSize = size }
                .overlay(alignment: .bottomTrailing) {
                    if zoom.isZoomed { zoomBadge }
                }
        }
        .clipped()
        .onAppear {
            scrollMonitor.start { delta in
                guard isHovering, zoom.isZoomed else { return false }
                zoom = zoom.panned(by: delta, in: frameSize)
                return true
            }
        }
        .onDisappear { scrollMonitor.stop() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(label ?? ""))
        .accessibilityValue(Text(zoom.isZoomed ? zoom.percentTitle : String(localized: "Fit")))
        .accessibilityIdentifier(identifier)
    }

    /// "250%" and Fit.
    private var zoomBadge: some View {
        HStack(spacing: Spacing.xSmall) {
            Text(zoom.percentTitle)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.85))
                .accessibilityIdentifier("\(identifier).percent")
            Button("Fit") {
                withAnimation(.snappy(duration: 0.25)) { zoom = .fit }
            }
            .controlSize(.small)
            .help(Text("Back to fit (or double-click)"))
            .accessibilityIdentifier("\(identifier).fit")
        }
        .padding(.leading, Spacing.small)
        .padding(.trailing, 3)
        .padding(.vertical, 3)
        .background(.black.opacity(0.55), in: Capsule())
        .padding(Spacing.small)
    }

    private func magnify(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = pinchStart ?? zoom
                pinchStart = start
                let anchor = CGPoint(x: (value.startAnchor.x - 0.5) * size.width, y: (value.startAnchor.y - 0.5) * size.height)
                zoom = start.pinched(by: value.magnification, around: anchor, in: size)
            }
            .onEnded { _ in pinchStart = nil }
    }

    private func pan(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                guard let start = panStart ?? (zoom.isZoomed ? zoom : nil) else { return }
                panStart = start
                zoom = start.panned(by: value.translation, in: size)
            }
            .onEnded { _ in panStart = nil }
    }

    /// 2× around the click, or back to fit.
    private func doubleClick(in size: CGSize) -> some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                let anchor = CGPoint(x: value.location.x - size.width / 2, y: value.location.y - size.height / 2)
                withAnimation(.snappy(duration: 0.25)) { zoom = zoom.toggled(around: anchor, in: size) }
            }
    }

    /// Two-finger scrolls in the app: `handler` takes the move and says
    /// whether it used it (only while zoomed with the pointer over the
    /// container), so a used scroll doesn't reach what's underneath.
    @MainActor
    private final class ScrollMonitor {
        private var monitor: Any?

        func start(_ handler: @escaping (CGSize) -> Bool) {
            stop()
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                // A mouse wheel moves in lines, a trackpad in points.
                let scale: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 10
                let delta = CGSize(width: event.scrollingDeltaX * scale, height: event.scrollingDeltaY * scale)
                return handler(delta) ? nil : event
            }
        }

        func stop() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }

        isolated deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}
