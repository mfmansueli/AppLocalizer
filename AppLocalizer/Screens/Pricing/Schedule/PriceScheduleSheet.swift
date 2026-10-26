//
//  PriceScheduleSheet.swift
//  AppLocalizer
//

import SwiftUI

/// When a subscription's price changes start and whether existing
/// subscribers keep their price, from the bottom bar's “Starts now” or
/// Review & Push's “Edit…”. Increases come with a warning that counts the
/// subscribers Apple may ask to agree.
struct PriceScheduleSheet: View {
    let productName: String
    let consent: PriceIncreaseConsent
    let onCancel: () -> Void
    let onSave: (PriceSchedule) -> Void

    @State private var startsOnDate: Bool
    @State private var day: Date
    @State private var preservesCurrentPrice: Bool
    private let earliestDay: Date

    init(
        productName: String,
        schedule: PriceSchedule,
        consent: PriceIncreaseConsent,
        today: Date,
        onCancel: @escaping () -> Void,
        onSave: @escaping (PriceSchedule) -> Void
    ) {
        self.productName = productName
        self.consent = consent
        self.onCancel = onCancel
        self.onSave = onSave
        let calendar = Calendar.current
        earliestDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) ?? today
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: today)) ?? today
        _startsOnDate = State(initialValue: schedule.isScheduled)
        _day = State(initialValue: schedule.startDay.flatMap { PriceSchedule.date(ofDay: $0) } ?? nextWeek)
        _preservesCurrentPrice = State(initialValue: schedule.preservesCurrentPrice)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Schedule price changes")
                    .font(.title2.weight(.semibold))
                Text("Applies to every price change in this push for \(productName).")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
            .padding(.horizontal, Spacing.xLarge)
            .padding(.top, Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            VStack(alignment: .leading, spacing: Spacing.medium) {
                startCard
                keepCard
                if consent.isEmpty {
                    Text("No increases in this push, so no subscriber has to agree to anything.")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                } else {
                    ConsentWarningBox(consent: consent)
                }
            }
            .padding(.horizontal, Spacing.xLarge)
            .padding(.bottom, Spacing.large)
            Divider()
            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("pricing.schedule.cancel")
                Button("Save") { onSave(schedule) }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("pricing.schedule.save")
            }
            .buttonBorderShape(.capsule)
            .padding(.horizontal, Spacing.xLarge)
            .padding(.vertical, Spacing.medium)
        }
        .frame(width: 580)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.scheduleSheet")
    }

    private var schedule: PriceSchedule {
        PriceSchedule(startDay: startsOnDate ? PriceSchedule.day(of: day) : nil, preservesCurrentPrice: preservesCurrentPrice)
    }

    private var startCard: some View {
        Card(padding: Spacing.medium) {
            Picker("Start", selection: $startsOnDate) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("As soon as Apple processes it")
                    Text("Usually within an hour.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                .tag(false)
                Text("On a date").tag(true)
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottomTrailing) {
                DatePicker("Start date", selection: $day, in: earliestDay..., displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.stepperField)
                    .disabled(!startsOnDate)
                    .accessibilityLabel(String(localized: "Start date"))
                    .accessibilityIdentifier("pricing.schedule.date")
            }
            .accessibilityIdentifier("pricing.schedule.start")
        }
    }

    private var keepCard: some View {
        Card(padding: Spacing.medium) {
            Toggle(isOn: $preservesCurrentPrice) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Keep the current price for existing subscribers")
                    Text("Only new subscribers get increases. Decreases reach everyone.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
            }
            .toggleStyle(.checkbox)
            .accessibilityIdentifier("pricing.schedule.keep")
        }
    }
}
