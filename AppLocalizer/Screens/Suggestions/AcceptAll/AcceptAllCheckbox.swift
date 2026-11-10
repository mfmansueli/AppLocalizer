//
//  AcceptAllCheckbox.swift
//  AppLocalizer
//

import SwiftUI

/// A checkbox with a mixed state, which SwiftUI's own only offers through
/// sources: used for a whole language or page.
struct AcceptAllCheckbox: View {
    let state: AcceptAllCheckState
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(state == .unchecked ? AnyShapeStyle(Palette.label3) : AnyShapeStyle(Palette.accent))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(value))
        .accessibilityAddTraits(.isToggle)
    }

    private var symbol: String {
        switch state {
        case .checked: "checkmark.square.fill"
        case .mixed: "minus.square.fill"
        case .unchecked: "square"
        }
    }

    private var value: String {
        switch state {
        case .checked: String(localized: "On")
        case .mixed: String(localized: "Some")
        case .unchecked: String(localized: "Off")
        }
    }
}

#Preview {
    HStack {
        AcceptAllCheckbox(state: .checked, label: "On") {}
        AcceptAllCheckbox(state: .mixed, label: "Mixed") {}
        AcceptAllCheckbox(state: .unchecked, label: "Off") {}
    }
    .padding()
}
