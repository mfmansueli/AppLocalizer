//
//  AcceptAllSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Accept All Languages (or Pages) before it accepts anything: languages on
/// the left with a checkbox each, the chosen language's suggestions on the
/// right, and "Don't ask again" in the footer.
struct AcceptAllSheet: View {
    @State var selection: AcceptAllSelection
    let onCancel: () -> Void
    /// The ticked suggestions' ids, and whether to stop asking.
    let onAccept: (Set<String>, Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                groupsColumn
                Divider()
                itemsColumn
            }
            Divider()
            footer
        }
        .frame(width: 780, height: 620)
        .accessibilityIdentifier("acceptAll.sheet")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(selection.kind.title)
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text(selection.subtitle)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, Spacing.medium)
    }

    private var groupsColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.tiny) {
                HStack(spacing: Spacing.tiny) {
                    Text(selection.kind.groupsTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.label2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("All") { selection.selectAll() }
                        .accessibilityIdentifier("acceptAll.all")
                    Button("None") { selection.selectNone() }
                        .accessibilityIdentifier("acceptAll.none")
                }
                .buttonStyle(.link)
                .font(.caption)
                .padding(.leading, Spacing.small)
                .padding(.trailing, Spacing.xxSmall)
                .padding(.bottom, Spacing.xSmall)
                ForEach(selection.groups) { group in
                    groupRow(group)
                }
            }
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, 10)
        }
        .frame(width: 232)
    }

    private func groupRow(_ group: AcceptAllGroup) -> some View {
        HStack(spacing: Spacing.small) {
            AcceptAllCheckbox(state: selection.state(of: group), label: String(localized: "Include \(group.title)")) {
                selection.toggle(group)
            }
            .accessibilityIdentifier("acceptAll.group.\(group.id)")
            Button {
                selection.focusedGroupID = group.id
            } label: {
                HStack(spacing: Spacing.small) {
                    if let region = group.regionCode {
                        FlagTile(regionCode: region)
                            .frame(width: 20)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(group.title)
                            .lineLimit(1)
                        Text(groupCaption(group))
                            .font(.caption2)
                            .foregroundStyle(Palette.label2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.label3)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("acceptAll.focus.\(group.id)")
        }
        .padding(.leading, Spacing.small)
        .padding(.trailing, Spacing.xSmall)
        .padding(.vertical, Spacing.xxSmall)
        .background(
            group.id == selection.focusedGroupID ? AnyShapeStyle(Palette.fill2) : AnyShapeStyle(.clear),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func groupCaption(_ group: AcceptAllGroup) -> String {
        let count = String(localized: "\(selection.selectedCount(in: group)) of \(group.items.count)")
        return group.isNewPage ? "\(count) · \(String(localized: "new page"))" : count
    }

    @ViewBuilder
    private var itemsColumn: some View {
        if let group = selection.focusedGroup {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Spacing.small) {
                    Text(group.title)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(selection.focusedCountText)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Palette.label2)
                    Button(selection.focusedToggleTitle) { selection.toggleFocusedGroup() }
                        .controlSize(.small)
                        .accessibilityIdentifier("acceptAll.toggleFocused")
                }
                .padding(.horizontal, Spacing.large)
                .padding(.top, Spacing.medium)
                .padding(.bottom, Spacing.small)
                if let text = selection.focusedNewPageText {
                    Banner(kind: .info, title: text, isInline: true) { EmptyView() }
                        .padding(.horizontal, Spacing.large)
                        .padding(.bottom, Spacing.small)
                }
                ScrollView {
                    VStack(spacing: Spacing.xSmall) {
                        ForEach(group.items) { item in
                            AcceptAllItemRow(item: item, isSelected: selection.isSelected(item), isRightToLeft: group.isRightToLeft) {
                                selection.toggle(item)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.bottom, Spacing.medium)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            Spacer()
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Toggle(isOn: $selection.dontAskAgain) {
                VStack(alignment: .leading, spacing: Spacing.tiny) {
                    Text(selection.kind.dontAskTitle)
                        .font(.caption)
                    Text("You can still undo right after, and turn this back on next to the button or in Settings → Suggestions.")
                        .font(.caption2)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.checkbox)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("acceptAll.dontAsk")
            Text(selection.summary)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.label2)
                .fixedSize()
                .accessibilityIdentifier("acceptAll.summary")
            Button("Cancel", role: .cancel, action: onCancel)
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("acceptAll.cancel")
            Button(selection.acceptTitle) {
                onAccept(selection.selected, selection.dontAskAgain)
            }
            .keyboardShortcut(.defaultAction)
            .disabled(selection.selectedCount == 0)
            .accessibilityIdentifier("acceptAll.accept")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, Spacing.medium)
    }
}

#Preview {
    AcceptAllSheet(
        selection: AcceptAllSelection(kind: .storePage, groups: [
            AcceptAllGroup(id: "en-US", title: "English (U.S.)", regionCode: "US", items: [
                AcceptAllItem(id: "1", title: "Subtitle", source: .builtIn, current: "Old", suggested: "New", reason: "Why."),
            ]),
            AcceptAllGroup(id: "he", title: "Hebrew", regionCode: "IL", isNewPage: true, isRightToLeft: true, items: [
                AcceptAllItem(id: "2", title: "Name", source: .assistant(client: "Claude Code"), current: "", suggested: "לומן", reason: "Why."),
            ]),
        ]),
        onCancel: {},
        onAccept: { _, _ in }
    )
}
