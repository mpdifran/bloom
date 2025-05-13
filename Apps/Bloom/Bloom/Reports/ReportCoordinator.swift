//
//  ReportCoordinator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-06.
//

import SwiftUI
import CoreHealth

private extension String {
    static let lastMorningReportNotificationDate = "ReportCoordinator.lastMorningReportNotificationDate"
}

final actor ReportCoordinator {
    static let shared = ReportCoordinator()

    private var lastMorningReportNotificationDate: Date? {
        didSet {
            UserDefaults.group.set(lastMorningReportNotificationDate, forKey: .lastMorningReportNotificationDate)
        }
    }

    private init() {
        if let date = UserDefaults.group.object(forKey: .lastMorningReportNotificationDate) as? Date {
            self.lastMorningReportNotificationDate = date
        }
    }
}

extension ReportCoordinator {

    func didDetectWakeUp(sleepAnalysis: SleepAnalysis? = nil) async {
        guard await ReportCoordinatorViewModel.shared.showMorningReportOnWakeUp else { return }

        if let lastMorningReportNotificationDate {
            if Calendar.current.isDateInToday(lastMorningReportNotificationDate) {
                return
            }
        }

        let message: String?
        if let sleepAnalysis, Calendar.current.isDateInToday(sleepAnalysis.endDate) {
            message = sleepAnalysis.sleepOneLiner
        } else {
            message = nil
        }

        await NotificationManager.shared.sendGoodMorningNotification(message: message)

        lastMorningReportNotificationDate = .now
    }
}
