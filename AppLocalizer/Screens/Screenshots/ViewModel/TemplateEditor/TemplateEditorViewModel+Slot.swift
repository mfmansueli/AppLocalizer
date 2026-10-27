//
//  TemplateEditorViewModel+Slot.swift
//  AppLocalizer
//

import Foundation

// The inspector's last section: this slot's layout and overrides.
extension TemplateEditorViewModel {
    /// "SLOT 3 · SEARCH".
    var slotHeader: String {
        let name = screenshots.document?.slotName(slot) ?? ""
        return String(localized: "Slot \(slot + 1) · \(name)")
    }

    var slotLayout: TemplateSlot.Layout {
        guard let template, template.slots.indices.contains(slot) else { return .standard }
        return template.slots[slot].layout
    }

    func setSlotLayout(_ layout: TemplateSlot.Layout) {
        set("slots.\(slot).layout", to: .string(layout.rawValue))
    }

    /// The slot's overrides as changes from the template, for the list
    /// with a clear button each.
    var slotOverrides: [TemplateChange] {
        guard let template, template.slots.indices.contains(slot) else { return [] }
        return template.slots[slot].over.keys.sorted().map { path in
            TemplateChange(path: "slots.\(slot).over.\(path)", old: template.value(at: path), new: template.slots[slot].over[path])
        }
    }

    var hasSlotOverrides: Bool { !slotOverrides.isEmpty }

    /// The headline size this slot uses: its override, else the
    /// template's.
    var slotHeadlineSize: Double {
        template?.value(at: "caption.headline.size", slot: slot)?.doubleValue ?? 112
    }

    /// Sets this slot's headline size; the template's size clears the
    /// override. The applier refuses a size under the smallest size.
    func setSlotHeadlineSize(_ size: Double) {
        let path = "slots.\(slot).over.caption.headline.size"
        let isTemplateSize = template?.caption.headline.size == size
        set(path, to: isTemplateSize ? .null : .double(size))
    }

    /// Clears one override; the slot follows the template again there.
    func clearOverride(_ change: TemplateChange) {
        set(change.path, to: .null)
    }

    /// Reset Slot: every override cleared.
    func resetSlot() {
        let operations = slotOverrides.map { TemplateOperation.replace($0.path, with: .null) }
        guard !operations.isEmpty else { return }
        apply(operations)
    }

    /// The note under the slot's controls.
    var slotNote: String {
        if slotLayout == .hero {
            return String(localized: "Hero: a 6% larger headline, room for a subhead and a slightly smaller device. Slot 1 is the one people see first.")
        }
        return hasSlotOverrides
            ? String(localized: "This slot overrides the template where listed. Everything else follows the template.")
            : String(localized: "Follows the template. Change a value here to override it for this slot only.")
    }
}
