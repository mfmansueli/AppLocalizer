//
//  ReviewFullSizeViewer.swift
//  AppLocalizer
//

import SwiftUI

/// Review & Push's full-size viewer over the sheet (`FullSizeViewerChrome`):
/// a set's slots with Live Now | New (or ↑ ↓) to compare a slot's two
/// sides, or a card's languages, where the App Preview plays with its
/// controls and a motion header or search image on repeat. Pinch on the
/// trackpad to zoom; Space plays or pauses a movie and closes on a still.
struct ReviewFullSizeViewer: View {
    let viewModel: ReviewPushViewModel
    let viewer: ReviewViewer

    @State private var previewPlayer = AppPreviewPlayerModel()
    @State private var loopPlayer = AppPreviewPlayerModel()

    var body: some View {
        FullSizeViewerChrome(
            identifier: "review.viewer",
            title: viewer.current.title,
            subtitle: viewer.subtitle,
            countTitle: viewer.list.countTitle,
            hasPrevious: viewer.list.hasPrevious,
            hasNext: viewer.list.hasNext,
            onStep: step,
            onClose: close,
            onSpace: space,
            onVerticalStep: viewer.current.comparesSides ? { _ in viewModel.flipViewerSide() } : nil
        ) {
            if viewer.current.comparesSides { sidePicker }
        } content: { size in
            ReviewViewerContentView(
                viewModel: viewModel, item: viewer.current, side: viewer.shownSide,
                previewPlayer: previewPlayer, loopPlayer: loopPlayer, size: size
            )
            .id(viewer.contentID)
        }
        .onDisappear(perform: pausePlayers)
    }

    /// Live Now | New.
    private var sidePicker: some View {
        Picker("Show", selection: Binding(get: { viewer.shownSide }, set: { viewModel.showViewerSide($0) })) {
            ForEach(ReviewViewerSide.allCases, id: \.self) { side in
                Text(side.title).tag(side)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .help(Text("What’s live now, or what the push sends (↑ ↓)"))
        .accessibilityIdentifier("review.viewer.side")
    }

    private func step(_ offset: Int) {
        pausePlayers()
        viewModel.stepViewer(offset)
    }

    private func close() {
        pausePlayers()
        viewModel.closeViewer()
    }

    private func space() {
        if viewer.current.content.isAppPreview {
            previewPlayer.toggle()
        } else if viewer.current.content.isMotion {
            loopPlayer.toggle()
        } else {
            close()
        }
    }

    private func pausePlayers() {
        previewPlayer.pause()
        loopPlayer.pause()
    }
}
