//
//  ReportCoordinatorViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

import SwiftUI

private extension String {
  static let morningReportDate = "ReportCoordinator.morningReportDate"
  static let eveningReportDate = "ReportCoordinator.eveningReportDate"
  static let showMorningReportOnWakeUp = "ReportCoordinator.showMorningReportOnWakeUp"
}

@Observable @MainActor
final class ReportCoordinatorViewModel {
  static let shared = ReportCoordinatorViewModel()

  var morningReportDate: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now {
    didSet {
      UserDefaults.group.set(morningReportDate, forKey: .morningReportDate)
    }
  }

  var eveningReportDate: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now) ?? .now {
    didSet {
      UserDefaults.group.set(eveningReportDate, forKey: .eveningReportDate)
      Task {
        await ReportCoordinator.shared.scheduleNotifications()
      }
    }
  }

  var showMorningReportOnWakeUp: Bool = true {
    didSet {
      UserDefaults.group.set(showMorningReportOnWakeUp, forKey: .showMorningReportOnWakeUp)
    }
  }

  private init() {
    UserDefaults.group.register(defaults: [.showMorningReportOnWakeUp : true])

    if let date = UserDefaults.group.object(forKey: .morningReportDate) as? Date {
      self.morningReportDate = date
    }
    if let date = UserDefaults.group.object(forKey: .eveningReportDate) as? Date {
      self.eveningReportDate = date
    }
    showMorningReportOnWakeUp = UserDefaults.group.bool(forKey: .showMorningReportOnWakeUp)

    Task {
      await ReportCoordinator.shared.scheduleNotifications()
    }
  }
}

extension ReportCoordinatorViewModel {

  var eveningReportStartDate: Date? {
    Calendar.current.applyHourMinuteSecond(to: .now, from: eveningReportDate)
  }

  func shouldShowEveningReport() -> Bool {
    guard let eveningReportStartDate else { return false }

    return eveningReportStartDate < .now
  }
}
