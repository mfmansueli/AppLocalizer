//
//  RetentionColumnsLayout.swift
//  AppLocalizer
//

import SwiftUI

/// The Retention page's three columns: the lists, the editor and the
/// preview. When the editor would get too narrow, the preview moves under
/// it; narrower still, everything stacks. Takes the width it's offered
/// and is as tall as its tallest column, so nothing it holds can push the
/// page wider than the window.
struct RetentionColumnsLayout: Layout {
    var listWidth: CGFloat = 270
    var previewWidth: CGFloat = 250
    var minEditorWidth: CGFloat = 340
    var spacing: CGFloat = Spacing.large

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let width = proposal.width ?? (listWidth + minEditorWidth + previewWidth + spacing * 2)
        let frames = frames(width: width, subviews: subviews)
        return CGSize(width: width, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        for (index, frame) in frames(width: bounds.width, subviews: subviews).enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    /// Each subview's frame at `width`: lists, editor, preview.
    func frames(width: CGFloat, subviews: Subviews) -> [CGRect] {
        func height(_ index: Int, _ width: CGFloat) -> CGFloat {
            subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        }
        guard subviews.count == 3 else {
            var y: CGFloat = 0
            return subviews.indices.map { index in
                defer { y += height(index, width) + spacing }
                return CGRect(x: 0, y: y, width: width, height: height(index, width))
            }
        }
        if width >= listWidth + minEditorWidth + previewWidth + spacing * 2 {
            let editorWidth = width - listWidth - previewWidth - spacing * 2
            return [
                CGRect(x: 0, y: 0, width: listWidth, height: height(0, listWidth)),
                CGRect(x: listWidth + spacing, y: 0, width: editorWidth, height: height(1, editorWidth)),
                CGRect(x: width - previewWidth, y: 0, width: previewWidth, height: height(2, previewWidth)),
            ]
        }
        if width >= listWidth + minEditorWidth + spacing {
            let editorWidth = width - listWidth - spacing
            let editorHeight = height(1, editorWidth)
            let x = listWidth + spacing + max(0, (editorWidth - previewWidth) / 2)
            return [
                CGRect(x: 0, y: 0, width: listWidth, height: height(0, listWidth)),
                CGRect(x: listWidth + spacing, y: 0, width: editorWidth, height: editorHeight),
                CGRect(x: x, y: editorHeight + spacing, width: min(previewWidth, editorWidth), height: height(2, previewWidth)),
            ]
        }
        let listHeight = height(0, width)
        let editorHeight = height(1, width)
        return [
            CGRect(x: 0, y: 0, width: width, height: listHeight),
            CGRect(x: 0, y: listHeight + spacing, width: width, height: editorHeight),
            CGRect(
                x: max(0, (width - previewWidth) / 2), y: listHeight + editorHeight + spacing * 2,
                width: min(previewWidth, width), height: height(2, previewWidth)
            ),
        ]
    }
}
