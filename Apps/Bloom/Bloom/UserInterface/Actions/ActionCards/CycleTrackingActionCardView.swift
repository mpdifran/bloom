//
//  CycleTrackingActionCardView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-03.
//

import SwiftUI
import HealthKit
import TelemetryDeck

struct CycleTrackingActionCardView: View {

  let performDismiss: (() -> Void)?

  init(performDismiss: (() -> Void)?) {
    self.performDismiss = performDismiss
  }

  @State private var date = Date.now
  @State private var flowType: HKCategoryValueMenstrualFlow = .none

  @State private var vitalsViewModel = VitalsViewModel.shared

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
    .tint(.mutedPink)
  }
}

private extension CycleTrackingActionCardView {

  @ViewBuilder
  var periodDateCell: some View {
    Group {
      if let mostRecentMenstrualCycle {
        if isCurrentPeriod {
          LabeledContent("Period Began") {
            Text(mostRecentMenstrualCycle.startDate, formatter: DateFormatter.justRelativeDateMedium)
          }
        } else {
          if let endDate = mostRecentMenstrualCycle.endDate {
            LabeledContent("Last Period Ended") {
              Text(endDate, formatter: DateFormatter.justRelativeDateMedium)
            }
          } else {
            LabeledContent("Last Period Started") {
              LabeledContent("Period Began") {
                Text(mostRecentMenstrualCycle.startDate, formatter: DateFormatter.justRelativeDateMedium)
              }
            }
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
      DatePicker("", selection: $date)
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

  func logCycle() async throws -> Bool {
    var isNewCycle = flowType.indicatesBeginningOfCycle
    if let mostRecentMenstrualCycle, isCurrentPeriod {
      isNewCycle = false
    }

    let metadata: [String : Any] = [
      HKMetadataKeyMenstrualCycleStart : isNewCycle
    ]

    let sample = HKCategorySample(
      type: HKCategoryType(.menstrualFlow),
      value: flowType.rawValue,
      start: date,
      end: date,
      metadata: metadata
    )

    try await HealthStoreModifier.shared.write(sample: sample)
    TelemetryDeck.signal("Log Period")
    return true
  }
}

#Preview {
  PreviewSheetPresent {
    CycleTrackingActionCardView { }
  }
}
