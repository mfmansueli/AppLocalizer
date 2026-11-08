//
//  DisplayTypeMenu.swift
//  AppLocalizer
//

import SwiftUI

/// The display type the Sets matrix shows: the sizes Apple requires
/// (iPhone Duo's from April 2027), then the ones this app has no template
/// for, with why.
struct DisplayTypeMenu: View {
    @Bindable var viewModel: ScreenshotsViewModel

    var body: some View {
        Menu {
            Section(String(localized: "Required by Apple")) {
                ForEach(viewModel.renderedDisplays) { type in
                    Toggle(isOn: selection(type)) {
                        Text(type.title)
                        Text(verbatim: Self.subtitle(type, size: viewModel.pixelSize(for: type)))
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
            Label(viewModel.displayType.title, systemImage: viewModel.displayType.symbolName)
        }
        .menuStyle(.button)
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .fixedSize()
        .accessibilityLabel(Text("Display type, \(viewModel.displayType.title)"))
        .accessibilityIdentifier("screenshots.displayType")
    }

    /// "1320 × 2868 px"; iPhone Duo's "2007 × 2853 px · from April 2027".
    static func subtitle(_ type: ScreenshotDisplayType, size: PixelSize) -> String {
        guard type.upcomingRequirement != nil else { return "\(size.title) px" }
        return "\(size.title) px · " + String(localized: "from April 2027")
    }

    private func selection(_ type: ScreenshotDisplayType) -> Binding<Bool> {
        Binding {
            viewModel.displayType == type
        } set: { isOn in
            if isOn { viewModel.displayType = type }
        }
    }
}
