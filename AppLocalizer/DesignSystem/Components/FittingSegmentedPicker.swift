//
//  FittingSegmentedPicker.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// A segmented picker whose segments are as wide as their titles. SwiftUI's
/// `.segmented` style makes every segment as wide as the longest one, which
/// at 1200 pt pushes Review & Push into the toolbar's overflow menu.
struct FittingSegmentedPicker<Value: Hashable>: NSViewRepresentable {
    let label: String
    let options: [(value: Value, title: String)]
    @Binding var selection: Value

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl(
            labels: options.map(\.title),
            trackingMode: .selectOne,
            target: context.coordinator,
            action: #selector(Coordinator.changed(_:))
        )
        control.segmentDistribution = .fit
        control.setAccessibilityLabel(label)
        control.setContentHuggingPriority(.required, for: .horizontal)
        return control
    }

    func updateNSView(_ control: NSSegmentedControl, context: Context) {
        context.coordinator.parent = self
        if control.segmentCount != options.count {
            control.segmentCount = options.count
        }
        for (index, option) in options.enumerated() where control.label(forSegment: index) != option.title {
            control.setLabel(option.title, forSegment: index)
        }
        control.selectedSegment = options.firstIndex { $0.value == selection } ?? -1
        // `.disabled` on the SwiftUI side.
        if control.isEnabled != context.environment.isEnabled {
            control.isEnabled = context.environment.isEnabled
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: FittingSegmentedPicker

        init(parent: FittingSegmentedPicker) {
            self.parent = parent
        }

        @objc func changed(_ sender: NSSegmentedControl) {
            guard parent.options.indices.contains(sender.selectedSegment) else { return }
            parent.selection = parent.options[sender.selectedSegment].value
        }
    }
}

#Preview {
    @Previewable @State var selection = AppWorkspaceSection.overview
    FittingSegmentedPicker(
        label: "Section",
        options: AppWorkspaceSection.allCases.map { ($0, $0.title) },
        selection: $selection
    )
    .padding()
}
