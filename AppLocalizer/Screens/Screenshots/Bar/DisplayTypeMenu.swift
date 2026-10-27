//
//  DisplayTypeMenu.swift
//  AppLocalizer
//

import SwiftUI

/// The display type the Sets matrix shows: the two sizes Apple requires,
/// then the ones this app has no template for, with why.
struct DisplayTypeMenu: View {
    @Bindable var viewModel: ScreenshotsViewModel

    var body: some View {
        Menu {
            Section(String(localized: "Required by Apple")) {
                ForEach(ScreenshotDisplayType.rendered) { type in
                    Toggle(isOn: selection(type)) {
                        Text(type.title)
                        Text(verbatim: "\(viewModel.pixelSize(for: type).title) px")
                    }
                    .accessibilityIdentifier("screenshots.display.\(type.shortTitle)")
                }
            }
            let notes = viewModel.otherDisplayTypeNotes
            if !notes.isEmpty {
                Section(String(localized: "Not in this app")) {
                    ForEach(notes, id: \.0) { type, note in
                        Button {} label: {
                            Text(type.title)
                            Text(note)
                        }
                        .disabled(true)
                    }
                }
            }
        } label: {
            Label(viewModel.displayType.title, systemImage: viewModel.displayType.isTablet ? "ipad" : "iphone")
        }
        .menuStyle(.button)
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .fixedSize()
        .accessibilityLabel(Text("Display type, \(viewModel.displayType.title)"))
        .accessibilityIdentifier("screenshots.displayType")
    }

    private func selection(_ type: ScreenshotDisplayType) -> Binding<Bool> {
        Binding {
            viewModel.displayType == type
        } set: { isOn in
            if isOn { viewModel.displayType = type }
        }
    }
}
