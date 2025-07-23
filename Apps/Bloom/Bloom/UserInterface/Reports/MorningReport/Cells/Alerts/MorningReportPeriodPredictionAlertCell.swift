//
//  MorningReportPeriodPredictionAlertCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import SwiftUI

struct MorningReportPeriodPredictionAlertCell: View {
  let predictedPeriodDate: Date

  var body: some View {
    MorningReportAlertCell(
      title: title,
      message: summary) {
        DayCapsule(
            dayNumber: "",
            highlightKind: .partial,
            isToday: false
        )
      }
      .tint(.mutedPink)
  }
}

private extension MorningReportPeriodPredictionAlertCell {

  var isLate: Bool {
    let startOfDay = Calendar.current.startOfDay(for: .now)

    return predictedPeriodDate < startOfDay
  }

  var title: String {
    if isLate {
      "Late Period"
    } else {
      "Upcoming Period"
    }
  }

  var summary: String {
    if isLate {
      "Your period is late. It was predicted to start \(DateFormatter.justRelativeDateMedium.string(from: predictedPeriodDate))."
    } else {
      "Your period is expected to start \(DateFormatter.justRelativeDateMedium.string(from: predictedPeriodDate))."
    }
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      MorningReportPeriodPredictionAlertCell(predictedPeriodDate: .now)
    }
    .groupedBackground()
  }
}
