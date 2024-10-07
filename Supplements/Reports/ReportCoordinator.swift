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
            Task {
                await scheduleEveningReport()
            }
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

        Task {
            await scheduleEveningReport()
            await NotificationManager.shared.scheduleFocusAreaNotification()
        }
    }
}

extension ReportCoordinator {

    func didDetectWakeUp(sleepAnalysis: SleepAnalysis? = nil) async {
        guard showMorningReportOnWakeUp else { return }

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

        await NotificationManager.shared.sendGoodMorningNotification(message: message, delay: 60 * 1)

        lastMorningReportNotificationDate = .now
    }

    func scheduleEveningReport() async {
        let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: eveningReportDate)

        await NotificationManager.shared.scheduleEveningReportNotification(dateComponents: dateComponents)
    }

    func shouldShowEveningReport() -> Bool {
        let now = Date.now
        guard let eveningStartDate = Calendar.current.applyHourMinuteSecond(to: now, from: eveningReportDate) else {
            return false
        }

        return eveningStartDate < now
    }
}
