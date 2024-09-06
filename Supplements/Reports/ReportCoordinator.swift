//
//  ReportCoordinator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-06.
//

import SwiftUI

private extension String {
    static let morningReportDate = "ReportCoordinator.morningReportDate"
    static let eveningReportDate = "ReportCoordinator.eveningReportDate"
    static let showMorningReportOnWakeUp = "ReportCoordinator.showMorningReportOnWakeUp"
    static let lastMorningReportNotificationDate = "ReportCoordinator.lastMorningReportNotificationDate"
}

final class ReportCoordinator: ObservableObject {
    static let shared = ReportCoordinator()

    @Published var morningReportDate: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now {
        didSet {
            UserDefaults.group.set(morningReportDate, forKey: .morningReportDate)
        }
    }

    @Published var eveningReportDate: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now) ?? .now {
        didSet {
            UserDefaults.group.set(eveningReportDate, forKey: .eveningReportDate)
        }
    }

    @AppStorage(.showMorningReportOnWakeUp, store: .group) var showMorningReportOnWakeUp: Bool = true

    private var lastMorningReportNotificationDate: Date? {
        didSet {
            UserDefaults.group.set(lastMorningReportNotificationDate, forKey: .lastMorningReportNotificationDate)
        }
    }

    private init() {
        if let date = UserDefaults.group.object(forKey: .morningReportDate) as? Date {
            self.morningReportDate = date
        }
        if let date = UserDefaults.group.object(forKey: .eveningReportDate) as? Date {
            self.eveningReportDate = date
        }
        if let date = UserDefaults.group.object(forKey: .lastMorningReportNotificationDate) as? Date {
            self.lastMorningReportNotificationDate = date
        }
    }
}

extension ReportCoordinator {

    func didDetectWakeUp() async {
        guard showMorningReportOnWakeUp else { return }

        if let lastMorningReportNotificationDate {
            if Calendar.current.isDateInToday(lastMorningReportNotificationDate) {
                return
            }
        }

        let message: String?
        if let sleepAnalysis = HealthManager.shared.sleepAnalysis7Days?.last, Calendar.current.isDateInToday(sleepAnalysis.endDate) {
            message = sleepAnalysis.sleepOneLiner
        } else {
            message = nil
        }

        await NotificationManager.shared.sendGoodMorningNotification(message: message, delay: 60 * 1)

        lastMorningReportNotificationDate = .now
    }
}
