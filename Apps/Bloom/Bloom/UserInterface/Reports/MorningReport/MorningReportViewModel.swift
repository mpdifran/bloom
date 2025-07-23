//
//  GoodMorningViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Foundation
import CoreHealth

extension MorningReportView.ViewModel {
  enum AlertKind: Sendable, Identifiable {
    var id: String {
      switch self {
      case .periodPrediction(let date):
        return "periodPrediction_\(date.timeIntervalSince1970)"
      case .intenseActivity(let value):
        return "intenseActivity_\(value)"
      case .sedentaryActivity:
        return "sedentaryActivity"
      }
    }

    case periodPrediction(Date)
    case intenseActivity(Double)
    case sedentaryActivity
  }
}

extension MorningReportView {
  @MainActor @Observable
  final class ViewModel {
    
  }
}

extension MorningReportView.ViewModel {

  var alerts: [MorningReportView.ViewModel.AlertKind] {
    var alerts = [MorningReportView.ViewModel.AlertKind]()

    if let date = relevantPredictedPeriodDate {
      alerts.append(.periodPrediction(date))
    }
    if let ratio = intenseActivityLevelRatio {
      alerts.append(.intenseActivity(ratio))
    }
    if hasSedentaryStreak {
      alerts.append(.sedentaryActivity)
    }

    return alerts
  }
}

extension MorningReportView.ViewModel {

  var relevantPredictedPeriodDate: Date? {
    guard
      let periodDate = VitalsViewModel.shared.menstrualSummary?.nextPredictedPeriodDate,
      let remainingDays = Calendar.current.dateComponents([.day], from: .now, to: periodDate).day,
      remainingDays <= 4,
      remainingDays >= -3
    else {
      return nil
    }

    return periodDate
  }

  var intenseActivityLevelRatio: Double? {
    guard
      let energyRatioSample = VitalsViewModel.shared.activityLevelSummary?.details.energyRatioSamples.last(where: { Calendar.current.isDateInYesterday($0.date) }),
      ActivityLevelSummary.ActivityLevel(energyRatioSample.value) == .intense
    else {
      return nil
    }

    return energyRatioSample.value
  }

  var hasSedentaryStreak: Bool {
    VitalsViewModel.shared.activityLevelSummary?.details.hasSedentaryStreakLast3Days == true
  }
}
