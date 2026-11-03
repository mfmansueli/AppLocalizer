//
//  ExtrasReviewTile.swift
//  AppLocalizer
//

import SwiftUI

/// One extra waiting in review, as a tile in its card's grid: its
/// checkbox (off, and locked, while an error keeps it out), the language,
/// the image, its findings as pills, and while it's pushed, its status.
/// The findings' lines are under the grid (`ExtrasReviewSection`).
struct ExtrasReviewTile: View {
    let item: ExtrasReviewItem
    let extras: ExtrasPushController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Spacing.xSmall) {
                Toggle(isOn: binding) { EmptyView() }
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    .disabled(item.isBlocked || extras.isPushing)
                    .accessibilityLabel(Text("Include \(item.title)"))
                    .accessibilityIdentifier("review.extras.check.\(item.id)")
                Text(item.localeName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                if case let .appPreview(display, _) = item.content {
                    Text(display.shortTitle).font(.caption).foregroundStyle(Palette.label2).lineLimit(1)
                }
            }
            ExtrasFileThumbnail(url: item.fileURL, pixelSize: item.pixelSize, width: Self.width, maxHeight: 72)
                .frame(width: Self.width, height: 72)
                .opacity(item.isBlocked ? 0.55 : 1)
                .overlay(alignment: .bottomTrailing) {
                    if item.isMotion {
                        Text("\(AutopilotRun.timeTitle(Double(AutopilotArtworkMotion.loopSeconds))) loop")
                            .font(.system(size: 9, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.black.opacity(0.5), in: Capsule())
                            .padding(4)
                            .accessibilityIdentifier("review.extras.loop.\(item.id)")
                    }
                }
            pills
            if let status = extras.run?.statuses[item.id] {
                Text(status.title)
                    .font(.caption2)
                    .foregroundStyle(status.isFailure ? Palette.danger : Palette.label2)
                    .monospacedDigit()
                    .help(status.failureReason ?? "")
                    .accessibilityIdentifier("review.extras.status.\(item.id)")
            }
        }
        .frame(width: Self.width, alignment: .leading)
        .padding(Spacing.xSmall)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(item.headline.map { $0.isEmpty ? "" : "“\($0)”" } ?? "")
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.extras.item.\(item.id)")
    }

    static let width: CGFloat = 150

    /// Its findings' reasons, errors first; "No localization" when App Store
    /// Connect has none for the language.
    @ViewBuilder
    private var pills: some View {
        let errors = Array(Set(item.errors.map(\.shortReason))).sorted()
        let warnings = Array(Set(item.warnings.map(\.shortReason))).sorted()
        if !errors.isEmpty || !warnings.isEmpty || item.localizationID == nil || !item.problems.isEmpty {
            FlowLayout(spacing: 3, lineSpacing: 3) {
                ForEach(errors, id: \.self) { Pill(text: $0, style: .danger) }
                if !item.problems.isEmpty { Pill(text: String(localized: "Apple’s rules"), style: .danger) }
                if item.localizationID == nil { Pill(text: String(localized: "No localization"), style: .danger) }
                ForEach(warnings, id: \.self) { Pill(text: $0, style: .warning) }
            }
        }
    }

    private var binding: Binding<Bool> {
        Binding {
            extras.isChecked(item)
        } set: { isOn in
            if isOn != extras.isChecked(item) { extras.toggle(item) }
        }
    }
}
