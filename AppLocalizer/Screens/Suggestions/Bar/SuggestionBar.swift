//
//  SuggestionBar.swift
//  AppLocalizer
//

import SwiftUI

/// Above a language's (or page's) fields: how many suggestions wait, which
/// sources to show, Ask Claude Code… (Generate Suggestions… with an API key,
/// or Set Up Assistant…), Dismiss All and Accept All. The line under it offers the other languages' suggestions,
/// brings dismissed ones back, and narrows the fields to those with
/// something to decide. Accept All asks nothing first; the toast after it
/// has Undo.
struct SuggestionBar: View {
    let model: SuggestionBarModel
    let status: AssistantStatus
    @Binding var filter: SuggestionSourceFilter
    @Binding var showsOnlyFields: Bool
    /// The Ask popover, opened by Ask (here or from the Assistant button).
    @Binding var showsAskPopover: Bool
    /// "Only fields with suggestions or changes", where there are fields.
    var showsFieldsToggle = true
    /// While an assistant sends suggestions, the banner replaces Ask.
    var isStreaming = false
    /// The prompt "Ask …" copied, while it waits for the first suggestion.
    var askRequest: AssistantSuggestionRequest?
    /// Generate Suggestions…, with an API key.
    var generate: GenerateSuggestionsModel?
    /// False where an API key can't suggest anything.
    var canAsk = true
    var onAsk: () -> Void = {}
    var onPrepareGenerate: () -> Void = {}
    var onGenerate: () -> Void = {}
    var onCancelGenerate: () -> Void = {}
    var onSetUp: () -> Void = {}
    var onCopyPromptAgain: () -> Void = {}
    var onCancelAsk: () -> Void = {}
    var onDismissAll: () -> Void = {}
    var onAcceptAll: () -> Void = {}
    var onAcceptEverywhere: () -> Void = {}
    var onRestore: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            bar
            if model.hasSecondLine {
                secondLine
            }
        }
        .onChange(of: askRequest?.isReceiving) {
            if askRequest?.isReceiving == true { showsAskPopover = false }
        }
        .onChange(of: askRequest == nil) {
            if askRequest == nil { showsAskPopover = false }
        }
    }

    private var bar: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "sparkles")
                .foregroundStyle(Palette.machineTranslated)
                .accessibilityHidden(true)
            Group {
                if model.openCount > 0 {
                    Pill(text: model.countText, style: .machineTranslated)
                } else {
                    Text(model.countText)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(model.countText))
            .accessibilityIdentifier("suggestions.count")
            Picker("Show suggestions from", selection: $filter) {
                ForEach(model.segments) { segment in
                    Text(model.segmentTitle(segment)).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 420)
            .accessibilityIdentifier("suggestions.sourceFilter")
            Spacer(minLength: Spacing.small)
            // The buttons keep their titles; the filter narrows first.
            Group {
                if !isStreaming {
                    askButton
                }
                Button("Dismiss All", action: onDismissAll)
                    .disabled(model.visibleCount == 0)
                    .accessibilityIdentifier("suggestions.dismissAll")
                Button(String(localized: "Accept All (\(model.visibleCount))"), action: onAcceptAll)
                    .buttonStyle(.borderedProminent)
                    .disabled(model.visibleCount == 0)
                    .accessibilityIdentifier("suggestions.acceptAll")
            }
            .fixedSize()
            .layoutPriority(1)
        }
        .controlSize(.small)
        .padding(.leading, Spacing.medium)
        .padding(.trailing, Spacing.small)
        .padding(.vertical, 7)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
                .strokeBorder(Palette.separator2, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Suggestions"))
        .accessibilityIdentifier("suggestions.bar")
    }

    private var askButton: some View {
        Button(status.askTitle) {
            if status.isConnected {
                onAsk()
                showsAskPopover = true
            } else if status.isReady {
                onPrepareGenerate()
                showsAskPopover = true
            } else {
                onSetUp()
            }
        }
        .disabled(!canAsk)
        .accessibilityIdentifier("suggestions.ask")
        .popover(isPresented: $showsAskPopover, arrowEdge: .bottom) {
            if status.isReady, let generate {
                GenerateSuggestionsPopover(model: generate, onGenerate: onGenerate) {
                    showsAskPopover = false
                    onCancelGenerate()
                }
            } else if let askRequest {
                AskAssistantPopover(request: askRequest, onCopyAgain: onCopyPromptAgain) {
                    showsAskPopover = false
                    onCancelAsk()
                }
            }
        }
    }

    private var secondLine: some View {
        HStack(spacing: Spacing.xSmall) {
            if model.otherScopesCount > 0 {
                Text(model.otherScopesCount == 1
                    ? String(localized: "1 more in other languages.")
                    : String(localized: "\(model.otherScopesCount) more in other languages."))
                Button(String(localized: "Accept All \(model.everywhereCount) in Every Language"), action: onAcceptEverywhere)
                    .buttonStyle(.link)
                    .accessibilityIdentifier("suggestions.acceptEverywhere")
            }
            if model.dismissedCount > 0 {
                Button(String(localized: "Restore \(model.dismissedCount) Dismissed"), action: onRestore)
                    .buttonStyle(.link)
                    .accessibilityIdentifier("suggestions.restore")
            }
            Spacer(minLength: Spacing.small)
            if showsFieldsToggle {
                Toggle("Only fields with suggestions or changes", isOn: $showsOnlyFields)
                    .toggleStyle(.checkbox)
                    .accessibilityIdentifier("suggestions.onlyFields")
            }
        }
        .font(.caption)
        .foregroundStyle(Palette.label2)
        .controlSize(.small)
        .padding(.leading, Spacing.medium)
        .padding(.trailing, Spacing.xxSmall)
    }
}

#Preview {
    @Previewable @State var filter = SuggestionSourceFilter.all
    @Previewable @State var onlyFields = false
    @Previewable @State var showsAsk = false
    SuggestionBar(
        model: SuggestionBarModel(
            openCount: 5,
            totalCount: 6,
            countsBySource: [.builtIn: 2, .assistant: 3],
            assistantName: "Claude Code",
            filter: filter,
            dismissedCount: 1,
            everywhereCount: 9
        ),
        status: .connected(client: "Claude Code"),
        filter: $filter,
        showsOnlyFields: $onlyFields,
        showsAskPopover: $showsAsk
    )
    .padding()
    .frame(width: 820)
}
