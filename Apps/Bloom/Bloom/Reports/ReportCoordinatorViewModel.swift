//
//  ReportCoordinatorViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

import SwiftUI

private extension String {
  static let morningReportDate = "ReportCoordinator.morningReportDate"
  static let showMorningReportOnWakeUp = "ReportCoordinator.showMorningReportOnWakeUp"
  static let selectedCalendarIdentifiers = "ReportCoordinator.selectedCalendarIdentifiers"
}

@Observable @MainActor
final class ReportCoordinatorViewModel {
  static let shared = ReportCoordinatorViewModel()

  var morningReportDate: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now {
    didSet {
      UserDefaults.group.set(morningReportDate, forKey: .morningReportDate)
    }
  }

  var showMorningReportOnWakeUp: Bool = true {
    didSet {
      UserDefaults.group.set(showMorningReportOnWakeUp, forKey: .showMorningReportOnWakeUp)
    }
  }
  
  var selectedCalendarIdentifiers: Set<String> = [] {
    didSet {
      UserDefaults.group.set(Array(selectedCalendarIdentifiers), forKey: .selectedCalendarIdentifiers)
    }
  }
  
  var isLoadingMorningReport = false

  private init() {
    UserDefaults.group.register(defaults: [.showMorningReportOnWakeUp: true])

    if let date = UserDefaults.group.object(forKey: .morningReportDate) as? Date {
      self.morningReportDate = date
    }
    showMorningReportOnWakeUp = UserDefaults.group.bool(forKey: .showMorningReportOnWakeUp)
    
    if let identifiers = UserDefaults.group.object(forKey: .selectedCalendarIdentifiers) as? [String] {
      self.selectedCalendarIdentifiers = Set(identifiers)
    }
  }
}
