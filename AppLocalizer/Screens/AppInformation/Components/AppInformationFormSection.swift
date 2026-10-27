//
//  AppInformationFormSection.swift
//  AppLocalizer
//

import SwiftUI

/// A titled group of rows, drawn like a grouped form: the title in small
/// capitals above a rounded box, with optional controls on the title's
/// right (a version menu, a counter).
struct AppInformationFormSection<Content: View, Trailing: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(spacing: Spacing.small) {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                trailing()
            }
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card - 2, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card - 2, style: .continuous)
                    .strokeBorder(Palette.separator, lineWidth: 0.5)
            }
            .accessibilityElement(children: .contain)
        }
    }
}

extension AppInformationFormSection where Trailing == EmptyView {
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, content: content) { EmptyView() }
    }
}

#Preview {
    AppInformationFormSection(title: "Category") {
        AppInformationFormRow(label: "Primary") { Text("Lifestyle") }
        Divider()
        AppInformationFormRow(label: "Secondary", detail: "optional") { Text("Health & Fitness") }
    }
    .padding()
    .frame(width: 600)
}
