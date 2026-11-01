//
//  StoreProductPreviewCard.swift
//  AppLocalizer
//

import SwiftUI

/// "APP STORE PREVIEW": the product page as the App Store shows it, in the
/// chosen language and appearance, with the screenshots at real
/// proportions scrolling like the store. Right-to-left languages run
/// right to left.
struct StoreProductPreviewCard: View {
    let app: StoreApp
    let preview: StudioPreview
    @Binding var appearance: StoreAppearance
    let image: (StudioShot) -> CGImage?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            page
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("studio.store")
    }

    private var header: some View {
        HStack(spacing: Spacing.small) {
            Text("APP STORE PREVIEW")
                .font(.caption.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(Palette.label2)
            Text(preview.note)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
                .accessibilityIdentifier("studio.store.note")
            Spacer(minLength: Spacing.small)
            StudioSegmentedControl(
                label: String(localized: "Store appearance"),
                options: StoreAppearance.allCases.map { .init(value: $0, title: $0.title, key: $0.rawValue) },
                selection: $appearance,
                identifier: "studio.appearance"
            )
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .background(Palette.raised)
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            StoreProductHeader(app: app, preview: preview)
            if let empty = preview.emptyText, preview.shots.isEmpty {
                Text(empty)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
                    .padding(Spacing.xLarge)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1)
                    }
                    .accessibilityIdentifier("studio.store.empty")
            } else if preview.shots.isEmpty {
                Text("No screenshots on the App Store yet.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .accessibilityIdentifier("studio.store.empty")
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: Spacing.small) {
                        ForEach(preview.shots) { shot in
                            StudioShotView(shot: shot, image: image(shot), width: shotWidth, cornerFraction: preview.displayType == .watch ? 0.24 : 0.05)
                        }
                    }
                    .padding(.bottom, Spacing.xxSmall)
                }
                .scrollIndicators(.automatic)
                .accessibilityLabel(Text("Screenshots"))
                .accessibilityIdentifier("studio.store.shots")
            }
        }
        .padding(Spacing.large)
        .environment(\.layoutDirection, preview.isRightToLeft ? .rightToLeft : .leftToRight)
        .environment(\.colorScheme, appearance.colorScheme)
        .background(appearance == .dark ? Color(white: 0.07) : Color.white)
    }

    private var shotWidth: CGFloat {
        switch preview.displayType {
        case .iPad, .visionPro: 300
        case .iPhoneDuo: 240
        case .watch: 150
        default: 156
        }
    }
}
