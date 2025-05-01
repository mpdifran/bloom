//
//  CycleTrackingActionCardView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-03.
//

import SwiftUI
import HealthKit
import TelemetryDeck
import CoreHealth

struct CycleTrackingActionCardView: View {

  let performDismiss: (() -> Void)?

  init(
    date: Date? = nil,
    performDismiss: (() -> Void)? = nil
  ) {
    self._date = State(initialValue: date ?? Date.now)
    self.performDismiss = performDismiss
  }

  @State private var date: Date
  @State private var flowType: HKCategoryValueMenstrualFlow = .none

  @State private var vitalsViewModel = VitalsViewModel.shared

  @Environment(\.requestReview) private var requestReview

  private let allFlowTypes: [HKCategoryValueMenstrualFlow] = [.none, .light, .medium, .heavy]

  var body: some View {
    CardView {
      LargeTitleActionCard("Log Period") {
        HealthActionCardView(
          sampleTypes: [HKCategoryType(.menstrualFlow)],
          performDismiss: performDismiss
        ) {
          try await logCycle()
        } content: { (hasInserted, _) in
          flowSection
          dateCell
          periodDateCell
        }
      }
    }
    .task {
      await loadExistingSampleAndSetState()
    }
    .tint(.mutedPink)
  }
}

private extension CycleTrackingActionCardView {

  @ViewBuilder
  var periodDateCell: some View {
    Group {
      if let mostRecentMenstrualCycle {
        if isCurrentPeriod {
          LabeledContent("Current Period Started") {
            Text(mostRecentMenstrualCycle.startDate, formatter: DateFormatter.justRelativeDateMedium)
          }
        } else {
          LabeledContent("Most Recent Period Started") {
            Text(mostRecentMenstrualCycle.startDate, formatter: DateFormatter.justRelativeDateMedium)
          }
        }
      }
    }
    .cardContainer()
  }

  var flowSection: some View {
    VStack {
      SectionTitleView("Flow")
        .padding(.horizontal)

      HStack {
        Spacer()

        ForEach(allFlowTypes, id: \.self) { flow in
          MenstrualFlowIndicatorView(flow: flow, isSelected: flowType == flow)
            .onTapGesture {
              self.flowType = flow
            }

          Spacer()
        }
      }
      .cardContainer()
    }
    .sensoryFeedback(.selection, trigger: flowType)
    .animation(.easeInOut, value: flowType)
  }

  var dateCell: some View {
    LabeledContent("Date") {
      DatePicker("", selection: $date, displayedComponents: .date)
    }
    .cardContainer()
  }
}

private extension CycleTrackingActionCardView {

  var mostRecentMenstrualCycle: MenstrualCycle? {
    vitalsViewModel.menstrualSummary?.mostRecentCycle
  }

  var isCurrentPeriod: Bool {
    guard let mostRecentMenstrualCycle else { return false }

    let referenceDate = mostRecentMenstrualCycle.endDate ?? mostRecentMenstrualCycle.startDate

    let daysSinceLastCycle = Calendar.current.dateComponents(
      [.day],
      from: referenceDate,
      to: .now
    ).day ?? 0

    return daysSinceLastCycle < 7
  }
}

private extension CycleTrackingActionCardView {

  func loadExistingSampleAndSetState() async {
    let existingSamples = await HealthStoreFetcher.shared.fetchSamples(
      for: HKCategoryType(.menstrualFlow),
      dateRange: .duringDay(date)
    )

    guard
      let firstSample = existingSamples.first as? HKCategorySample,
      let flowType = HKCategoryValueMenstrualFlow(rawValue: firstSample.value)
    else { return }

    self.flowType = flowType
  }

  func logCycle() async throws -> Bool {
    var isNewCycle = flowType.indicatesBeginningOfCycle
    if isCurrentPeriod {
      isNewCycle = false
    }

    let metadata: [String: Any] = [
      HKMetadataKeyMenstrualCycleStart: isNewCycle
    ]

    let normalizedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date

    let existingSamples = await HealthStoreFetcher.shared.fetchSamples(
      for: HKCategoryType(.menstrualFlow),
      dateRange: .duringDay(date)
    )
    if existingSamples.isNotEmpty {
      try await HealthStoreModifier.shared.delete(existingSamples)
    }

    if flowType != .none {
      let sample = HKCategorySample(
        type: HKCategoryType(.menstrualFlow),
        value: flowType.rawValue,
        start: normalizedDate,
        end: normalizedDate,
        metadata: metadata
      )

      try await HealthStoreModifier.shared.write(sample)
      TelemetryDeck.signal("Log Period")
    }

    await VitalsCalculator.shared.forceFectchMenstrualSummary()

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }

    return true
  }
}

#Preview {
  PreviewSheetPresent {
    CycleTrackingActionCardView { }
  }
}
