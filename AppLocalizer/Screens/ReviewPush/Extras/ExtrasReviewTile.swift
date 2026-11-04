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
    /// Opens it large, with its card's other languages.
    let onOpen: () -> Void

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
            Button(action: onOpen) {
                ExtrasFileThumbnail(url: item.fileURL, pixelSize: item.pixelSize, width: Self.width, maxHeight: 72)
                    .frame(width: Self.width, height: 72)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(thumbnailHelp)
            .accessibilityLabel(Text(item.title))
            .accessibilityHint(isMovie ? Text("Plays it larger") : Text("Shows it larger"))
            .accessibilityIdentifier("review.extras.open.\(item.id)")
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
                        .allowsHitTesting(false)
                        .accessibilityIdentifier("review.extras.loop.\(item.id)")
                }
            }
            pills
            if let run = extras.run, let status = run.statuses[item.id] {
                pushStatus(status, in: run)
            }
        }
        .frame(width: Self.width, alignment: .leading)
        .padding(Spacing.xSmall)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            if extras.run?.activities[item.id] != nil {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Palette.accent, lineWidth: 1.5)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.extras.item.\(item.id)")
    }

    static let width: CGFloat = 150

    /// Its headline, then what a click does. (On the thumbnail, not the
    /// tile, so a failed push's reason shows on its own line's tooltip.)
    private var thumbnailHelp: String {
        let action = isMovie ? String(localized: "Click to play it larger") : String(localized: "Click to see it larger")
        guard let headline = item.headline, !headline.isEmpty else { return action }
        return "“\(headline)”\n\(action)"
    }

    /// While it's pushed: its place in line, its upload's bar, how long
    /// Apple has been processing it, done or why it failed.
    private func pushStatus(_ status: ExtrasPushStatus, in run: ExtrasPushRun) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                if status.isDone {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.positive).accessibilityHidden(true)
                }
                if case .processing = status, let since = run.activities[item.id]?.stepStartedAt {
                    TimelineView(.periodic(from: since, by: 1)) { context in
                        Text("Apple is processing · \(ExtrasPushRun.clock(context.date.timeIntervalSince(since)))")
                    }
                } else {
                    Text(run.pushItem(item.id).flatMap(run.queueTitle(of:)) ?? status.title)
                }
            }
            .font(.caption2)
            .foregroundStyle(status.isFailure ? Palette.danger : status.isDone ? Palette.positive : Palette.label2)
            .monospacedDigit()
            .help(status.failureReason ?? "")
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("review.extras.status.\(item.id)")
            if let reason = status.failureReason {
                Text(reason)
                    .font(.caption2)
                    .foregroundStyle(Palette.danger)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .help(reason)
                    .accessibilityIdentifier("review.extras.failure.\(item.id)")
            }
            if case let .uploading(fraction) = status {
                ProgressView(value: min(1, max(0, fraction)))
                    .progressViewStyle(.linear)
                    .controlSize(.mini)
                    .accessibilityHidden(true)
            }
        }
    }

    /// An App Preview or a motion image: it plays in the viewer.
    private var isMovie: Bool {
        item.isMotion || item.artworkKind == nil
    }

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
