//
//  SectionBar.swift
//  AppLocalizer
//

import SwiftUI

/// The bar under the toolbar that every section has: what's being edited on
/// the leading side (a subscription, a version), the section's view picker
/// and actions on the trailing side.
struct SectionBar<Leading: View, Trailing: View>: View {
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: Spacing.medium) {
            leading()
            Spacer(minLength: Spacing.medium)
            HStack(spacing: Spacing.small) {
                trailing()
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .frame(minHeight: 52)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

#Preview {
    SectionBar {
        SectionBarTitle(systemImage: "tag", title: "Lumen Plus Annual", subtitle: "lumen.plus.annual · 1 year · Approved", showsChevron: true)
    } trailing: {
        Picker("View", selection: .constant(0)) {
            Text("Prices").tag(0)
            Text("Offers").tag(1)
        }
        .pickerStyle(.segmented)
        .fixedSize()
    }
    .frame(width: 800)
}
