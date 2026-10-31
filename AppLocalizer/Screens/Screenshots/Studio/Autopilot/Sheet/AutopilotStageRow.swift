//
//  AutopilotStageRow.swift
//  AppLocalizer
//

import SwiftUI

/// One stage in the list: its number (a check once done, a spinner while
/// it runs, purple when it waits for you), title and who does it.
struct AutopilotStageRow: View {
    enum State {
        case done
        case current
        case running
        case yourTurn
        case upcoming
    }

    let step: AutopilotStage
    let who: String
    let problem: String?
    let state: State
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.small) {
                badge
                VStack(alignment: .leading, spacing: 1) {
                    Text(step.title)
                        .font(.callout.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(state == .upcoming ? Palette.label2 : Palette.label)
                    Text(problem ?? who)
                        .font(.caption)
                        .foregroundStyle(problem == nil ? Palette.label2 : Palette.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(isSelected ? Palette.fill2 : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(step.number). \(step.title), \(problem ?? who), \(stateText)"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("autopilot.stage.\(step.rawValue)")
    }

    private var badge: some View {
        ZStack {
            switch state {
            case .done:
                Circle().fill(Color.accentColor)
                Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
            case .running:
                Circle().strokeBorder(Palette.separator2, lineWidth: 1)
                ProgressView().controlSize(.mini)
            case .yourTurn:
                Circle().fill(Palette.machineTranslatedMark)
                Text("\(step.number)").font(.caption.weight(.semibold)).foregroundStyle(.white)
            case .current:
                Circle().fill(Color.accentColor)
                Text("\(step.number)").font(.caption.weight(.semibold)).foregroundStyle(.white)
            case .upcoming:
                Circle().strokeBorder(Palette.separator2, lineWidth: 1)
                Text("\(step.number)").font(.caption).foregroundStyle(Palette.label2)
            }
        }
        .frame(width: 22, height: 22)
    }

    private var stateText: String {
        switch state {
        case .done: String(localized: "done")
        case .current: String(localized: "current")
        case .running: String(localized: "running")
        case .yourTurn: String(localized: "your turn")
        case .upcoming: String(localized: "not yet")
        }
    }
}
