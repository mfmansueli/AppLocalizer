//
//  PrivacyWorksheet+Checklist.swift
//  AppLocalizer
//

import Foundation

// "Fill in App Store Connect": the steps from the reviewed answers, the
// person's ticks, and Mark as Published.
extension PrivacyWorksheet {
    /// The steps, from reviewed answers only.
    var checklistSteps: [PrivacyChecklistStep] {
        let answers = reviewedAnswers
        let collectsData = answers.collects == true
        var steps = [PrivacyChecklistStep(
            id: "s1",
            number: "1",
            title: String(localized: "Data collection"),
            body: collectsData
                ? String(localized: "Yes, we collect data from this app")
                : String(localized: "No, we do not collect data from this app")
        )]
        if collectsData {
            let types = answers.collectedTypes
            let byCategory = PrivacyDataCategory.allCases.compactMap { category -> String? in
                let names = types.filter { $0.category == category }.map(\.name)
                return names.isEmpty ? nil : "\(category.name): \(names.joined(separator: ", "))"
            }
            steps.append(PrivacyChecklistStep(
                id: "s2",
                number: "2",
                title: String(localized: "Select the data types, then Save"),
                body: byCategory.joined(separator: "\n")
            ))
            for (index, type) in types.enumerated() {
                guard let answer = answers.collected[type] else { continue }
                steps.append(PrivacyChecklistStep(
                    id: "d-\(type.rawValue)",
                    number: "3.\(index + 1)",
                    title: type.name,
                    body: Self.stepBody(for: answer),
                    isTypeStep: true
                ))
            }
        }
        steps.append(PrivacyChecklistStep(
            id: "s4",
            number: collectsData ? "4" : "2",
            title: String(localized: "Publish"),
            body: String(localized: "Click Publish at the top of the App Privacy page."),
            canCopy: false
        ))
        return steps
    }

    func isChecked(_ step: PrivacyChecklistStep) -> Bool {
        checkedSteps.contains(step.checkKey)
    }

    mutating func setChecked(_ step: PrivacyChecklistStep, _ isChecked: Bool) {
        if isChecked {
            checkedSteps.insert(step.checkKey)
        } else {
            checkedSteps.remove(step.checkKey)
        }
    }

    /// "3 of 12 steps".
    var checkedStepCount: Int {
        checklistSteps.count(where: isChecked)
    }

    var allStepsChecked: Bool {
        checklistSteps.allSatisfy(isChecked)
    }

    /// "Mark as Published in App Store Connect": keeps the date and a copy
    /// of the reviewed answers.
    mutating func markPublished(at date: Date) {
        publication = PrivacyPublication(date: date, snapshot: reviewedAnswers)
    }

    /// "Purposes: App Functionality\nLinked to the user’s identity: Yes\nUsed
    /// for tracking: No".
    static func stepBody(for answer: PrivacyAnswer) -> String {
        let purposes = answer.sortedPurposes.map(\.title).joined(separator: ", ")
        let linked = answer.linked ? String(localized: "Yes") : String(localized: "No")
        let tracking = answer.tracking ? String(localized: "Yes") : String(localized: "No")
        return [
            String(localized: "Purposes: \(purposes)"),
            String(localized: "Linked to the user’s identity: \(linked)"),
            String(localized: "Used for tracking: \(tracking)"),
        ].joined(separator: "\n")
    }
}
