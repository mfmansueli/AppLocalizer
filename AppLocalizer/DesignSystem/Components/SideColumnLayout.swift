//
//  SideColumnLayout.swift
//  AppLocalizer
//

import SwiftUI

/// A page's content with a fixed-width column beside it (Age Rating's
/// rating preview). When the content would get narrower than
/// `minimumMainWidth`, or than it can be, the column goes above it at full
/// width instead of pushing the page wider than the window. Both children
/// keep their identity either way, so their state survives a resize.
///
/// Takes two children: the content, then the column.
struct SideColumnLayout: Layout {
    /// The column's width beside the content.
    var sideWidth: CGFloat
    /// The narrowest the content gets beside the column.
    var minimumMainWidth: CGFloat
    var spacing: CGFloat = Spacing.xLarge

    /// Whether the column fits beside content that can't be narrower than
    /// `mainMinimumWidth`, in `width`. With no width to fit (an ideal size),
    /// it goes beside.
    func placesBeside(in width: CGFloat?, mainMinimumWidth: CGFloat) -> Bool {
        guard let width else { return true }
        return width - spacing - sideWidth >= max(minimumMainWidth, mainMinimumWidth)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        guard let (main, side) = pair(subviews) else { return .zero }
        if placesBeside(in: proposal.width, mainMinimumWidth: minimumWidth(of: main)) {
            let mainSize = main.sizeThatFits(ProposedViewSize(width: proposal.width.map { $0 - spacing - sideWidth }, height: nil))
            let sideSize = side.sizeThatFits(ProposedViewSize(width: sideWidth, height: nil))
            return CGSize(width: mainSize.width + spacing + sideWidth, height: max(mainSize.height, sideSize.height))
        }
        let stacked = ProposedViewSize(width: proposal.width, height: nil)
        let mainSize = main.sizeThatFits(stacked)
        let sideSize = side.sizeThatFits(stacked)
        return CGSize(width: max(mainSize.width, sideSize.width), height: sideSize.height + spacing + mainSize.height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        guard let (main, side) = pair(subviews) else { return }
        if placesBeside(in: bounds.width, mainMinimumWidth: minimumWidth(of: main)) {
            main.place(
                at: CGPoint(x: bounds.minX, y: bounds.minY),
                proposal: ProposedViewSize(width: bounds.width - spacing - sideWidth, height: nil)
            )
            side.place(at: CGPoint(x: bounds.maxX - sideWidth, y: bounds.minY), proposal: ProposedViewSize(width: sideWidth, height: nil))
        } else {
            let stacked = ProposedViewSize(width: bounds.width, height: nil)
            let sideHeight = side.sizeThatFits(stacked).height
            side.place(at: CGPoint(x: bounds.minX, y: bounds.minY), proposal: stacked)
            main.place(at: CGPoint(x: bounds.minX, y: bounds.minY + sideHeight + spacing), proposal: stacked)
        }
    }

    private func pair(_ subviews: Subviews) -> (main: LayoutSubview, side: LayoutSubview)? {
        guard subviews.count == 2 else { return nil }
        return (subviews[0], subviews[1])
    }

    /// The content's own minimum: its controls that don't wrap.
    private func minimumWidth(of main: LayoutSubview) -> CGFloat {
        main.sizeThatFits(ProposedViewSize(width: 0, height: nil)).width
    }
}

#Preview {
    SideColumnLayout(sideWidth: 200, minimumMainWidth: 240) {
        Text("The questionnaire, as wide as the page allows.")
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background(.quaternary)
        Text("Preview")
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            .background(.tertiary)
    }
    .padding()
    .frame(width: 400)
}
