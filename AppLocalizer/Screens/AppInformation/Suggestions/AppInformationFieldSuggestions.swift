//
//  AppInformationFieldSuggestions.swift
//  AppLocalizer
//

import SwiftUI

/// Under an App Information row: who suggested the value waiting to be
/// pushed, with Undo, and the open suggestion for the field, question or
/// feature, or while Suggest Everything still owes one, its placeholder.
/// Categories, the release option and answers read by name; picked values
/// and answers have no Use and Edit.
struct AppInformationFieldSuggestions: View {
    let viewModel: AppInformationViewModel
    let slot: AppInformationSuggestionSlot

    init(viewModel: AppInformationViewModel, slot: AppInformationSuggestionSlot) {
        self.viewModel = viewModel
        self.slot = slot
    }

    init(viewModel: AppInformationViewModel, field: AppInformationSuggestionField) {
        self.init(viewModel: viewModel, slot: .field(field))
    }

    var body: some View {
        let provenance = viewModel.provenance(slot)
        let suggestion = viewModel.shownSuggestion(slot)
        let coming = viewModel.isComing(slot) ? viewModel.suggestionRun : nil
        if provenance != nil || suggestion != nil || coming != nil {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                if let provenance {
                    SuggestionProvenanceLine(provenance: provenance, currentValue: viewModel.suggestionValue(slot)) {
                        viewModel.undoSuggestion(slot)
                    }
                }
                if let suggestion {
                    FieldSuggestionCard(
                        fieldTitle: slot.title,
                        suggestion: suggestion,
                        current: slot.displayValue(viewModel.suggestionValue(slot)),
                        suggested: slot.displayValue(suggestion.value),
                        meta: viewModel.suggestionMeta(suggestion),
                        canUseAndEdit: slot.canUseAndEdit,
                        onDismiss: { viewModel.dismissSuggestion(suggestion) },
                        onUseAndEdit: { viewModel.useAndEditSuggestion(suggestion) },
                        onAccept: { viewModel.acceptSuggestion(suggestion) }
                    )
                } else if let coming {
                    SuggestionComingPlaceholder(client: coming.client, kind: placeholderKind)
                }
            }
            .padding(.horizontal, Spacing.medium + 2)
            .padding(.bottom, Spacing.small + 1)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("appInformation.suggestions.\(identifier)")
        }
    }

    private var placeholderKind: SuggestionComingPlaceholder.Kind {
        switch slot {
        case .field: .field
        case .ageRating: .question
        case .accessibility: .feature
        }
    }

    /// `copyright`, `age.wellness`, `accessibility.voiceOver`.
    private var identifier: String {
        switch slot {
        case let .field(field): field.rawValue
        case let .ageRating(question): "age.\(question.rawValue)"
        case let .accessibility(_, feature): "accessibility.\(feature.rawValue)"
        }
    }
}
