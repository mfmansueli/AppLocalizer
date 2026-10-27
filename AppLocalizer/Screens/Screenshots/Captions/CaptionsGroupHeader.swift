//
//  CaptionsGroupHeader.swift
//  AppLocalizer
//

import SwiftUI

/// "LOCALIZED SETS 12", or "NOT LOCALIZED 27 · Add Locales…".
struct CaptionsGroupHeader<Accessory: View>: View {
    let title: String
    let count: Int
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(spacing: Spacing.small) {
            Text(title)
                .textCase(.uppercase)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.label2)
            Text("\(count)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.label3)
            accessory()
                .font(.caption)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.top, Spacing.medium)
        .padding(.bottom, Spacing.xxSmall)
    }
}

extension CaptionsGroupHeader where Accessory == EmptyView {
    init(title: String, count: Int) {
        self.init(title: title, count: count) { EmptyView() }
    }
}
