//
//  PricingSegmentedControl.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// A native segmented control whose segments can be disabled one by one
/// and show a symbol instead of a title, which a SwiftUI segmented `Picker`
/// can't do on macOS. Used for Prices | Offers | Results and Table | Map |
/// Histogram, where some views arrive in a later update.
struct PricingSegmentedControl<Value: Hashable>: NSViewRepresentable {
    struct Segment {
        var value: Value
        var title: String?
        var systemImage: String?
        /// What VoiceOver and the tooltip say; required for symbol-only segments.
        var label: String
        var isEnabled = true
        var help: String?
    }

    let label: String
    let segments: [Segment]
    @Binding var selection: Value
    var identifier: String?

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl()
        control.trackingMode = .selectOne
        control.segmentDistribution = .fit
        control.target = context.coordinator
        control.action = #selector(Coordinator.changed(_:))
        control.setContentHuggingPriority(.required, for: .horizontal)
        return control
    }

    func updateNSView(_ control: NSSegmentedControl, context: Context) {
        context.coordinator.parent = self
        control.controlSize = context.environment.controlSize == .small ? .small : .regular
        control.setAccessibilityLabel(label)
        if let identifier { control.setAccessibilityIdentifier(identifier) }
        if control.segmentCount != segments.count { control.segmentCount = segments.count }
        for (index, segment) in segments.enumerated() {
            if let systemImage = segment.systemImage {
                control.setImage(NSImage(systemSymbolName: systemImage, accessibilityDescription: segment.label), forSegment: index)
                control.setLabel("", forSegment: index)
            } else {
                control.setLabel(segment.title ?? segment.label, forSegment: index)
            }
            control.setEnabled(segment.isEnabled, forSegment: index)
            control.setToolTip(segment.help ?? (segment.systemImage == nil ? nil : segment.label), forSegment: index)
        }
        control.selectedSegment = segments.firstIndex { $0.value == selection } ?? -1
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: PricingSegmentedControl

        init(parent: PricingSegmentedControl) {
            self.parent = parent
        }

        @objc func changed(_ sender: NSSegmentedControl) {
            guard parent.segments.indices.contains(sender.selectedSegment) else { return }
            parent.selection = parent.segments[sender.selectedSegment].value
        }
    }
}

#Preview {
    @Previewable @State var selection = 0
    PricingSegmentedControl(
        label: "View",
        segments: [
            .init(value: 0, title: "Prices", label: "Prices"),
            .init(value: 1, title: "Offers", label: "Offers", isEnabled: false),
            .init(value: 2, systemImage: "chart.bar", label: "Histogram"),
        ],
        selection: $selection
    )
    .fixedSize()
    .padding()
}
