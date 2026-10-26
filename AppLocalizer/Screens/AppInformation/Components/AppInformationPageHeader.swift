//
//  AppInformationPageHeader.swift
//  AppLocalizer
//

import SwiftUI

/// A page's title and the line under it, with optional controls on the
/// right (a badge, a link).
struct AppInformationPageHeader<Trailing: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Spacing.medium)
            HStack(spacing: Spacing.small) {
                trailing()
            }
        }
    }
}

extension AppInformationPageHeader where Trailing == EmptyView {
    init(title: String, subtitle: String) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

#Preview {
    AppInformationPageHeader(title: "General", subtitle: "Category and content rights apply to the whole app.") {
        Pill(text: "Complete")
    }
    .padding()
    .frame(width: 600)
}
