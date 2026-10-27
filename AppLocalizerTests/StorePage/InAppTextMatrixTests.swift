//
//  InAppTextMatrixTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("InAppTextMatrix")
struct InAppTextMatrixTests {
    private let matrix = StorePageSampleData.inAppTexts

    private func column(_ id: String) throws -> InAppTextColumn {
        try #require(matrix.columns.first { $0.id == id })
    }

    @Test func columnsAreTheGroupThenEachProduct() {
        #expect(matrix.columns.map(\.id) == [
            "group.name",
            "lumen.plus.monthly.name", "lumen.plus.monthly.description",
            "lumen.plus.annual.name", "lumen.plus.annual.description",
            "lumen.lifetime.name", "lumen.lifetime.description",
        ])
        #expect(matrix.columns.map(\.title).prefix(3) == ["Group name", "Monthly · name", "Monthly · description"])
        #expect(matrix.columns.last?.field == .purchaseDescription)
        #expect(matrix.columns[1].field == .subscriptionName)
        #expect(InAppTextColumn.groupName.productID == nil)
    }

    @Test func germanAnnualDescriptionIsOverTheLimit() throws {
        let annual = try column("lumen.plus.annual.description")
        let counter = matrix.counter(annual, in: .german)
        #expect(counter.text == "56 / 45")
        #expect(counter.isOverLimit)
        #expect(matrix.validation(of: annual, in: .german).isBlocking)
        #expect(matrix.counter(annual, in: .englishUS).text == "31 / 45")
        #expect(matrix.overLimitCount >= 1)
    }

    @Test func missingCells() throws {
        let lifetime = try column("lumen.lifetime.description")
        #expect(matrix.value(lifetime, in: .german).isEmpty)
        #expect(matrix.missingCount > 0)
        #expect(matrix.displayLocales.first == .englishUS)
        #expect(matrix.displayLocales.count == 10)
    }

    @Test func editsBecomeChanges() throws {
        var matrix = matrix
        let lifetime = try column("lumen.lifetime.description")
        let annual = try column("lumen.plus.annual.description")
        #expect(matrix.changes.isEmpty)

        matrix.edit(annual, in: .german, to: "Ein Jahr Lumen Plus – spare 33 %")
        matrix.acceptMachineTranslation("Alle Lumen Plus Funktionen, für immer", for: lifetime, in: .german)
        matrix.edit(lifetime, in: .korean, to: String(repeating: "루", count: 46))

        #expect(matrix.changes.map(\.id) == [
            "de-DE.lumen.plus.annual.description", "de-DE.lumen.lifetime.description", "ko.lumen.lifetime.description",
        ])
        #expect(matrix.changes.map(\.source) == [.you, .machineTranslation, .you])
        #expect(matrix.changes.map(\.isBlocked) == [false, false, true])
        #expect(matrix.changes.first?.title == "German · Annual · description")
        #expect(matrix.displayLocales.contains(.korean))

        matrix.discard(lifetime, in: .korean)
        matrix.discard(lifetime, in: .german)
        matrix.discard(annual, in: .german)
        #expect(matrix.changes.isEmpty)
    }

    @Test func primaryLocaleIsAlwaysIncluded() {
        let matrix = InAppTextMatrix(products: [], primaryLocale: .englishUS, locales: [.german], remote: [:])
        #expect(matrix.locales == [.englishUS, .german])
        #expect(matrix.columns == [.groupName])
        #expect(matrix.missingCount == 2)
    }
}
