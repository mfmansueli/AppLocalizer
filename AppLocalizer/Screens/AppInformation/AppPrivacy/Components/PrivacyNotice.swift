//
//  PrivacyNotice.swift
//  AppLocalizer
//

import SwiftUI

/// A tinted box in the worksheet: what a rescan changed (accent), or
/// something to act on (warning), with its buttons.
struct PrivacyNotice<Content: View, Actions: View>: View {
    var isWarning = false
    @ViewBuilder var content: () -> Content
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.small) {
            if isWarning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Palette.warningMark)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                content()
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: Spacing.small) {
                actions()
            }
            .controlSize(.small)
        }
        .padding(Spacing.medium)
        .background(isWarning ? Palette.warningTint : Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

extension PrivacyNotice where Actions == EmptyView {
    init(isWarning: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.init(isWarning: isWarning, content: content) { EmptyView() }
    }
}
