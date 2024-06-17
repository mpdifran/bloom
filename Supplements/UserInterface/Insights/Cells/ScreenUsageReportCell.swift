//
//  ScreenUsageReportCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-12.
//

import SwiftUI
import DeviceActivity
import ScreenControl

struct ScreenUsageReportCell: View {

    @ObservedObject private var screenUseController = ScreenUseController.shared

    @State private var filter: DeviceActivityFilter?

    var body: some View {
        Section {
            VStack {
                SleepProgramSectionHeader(
                    title: "Screen Use",
                    subtitle: "During Bedtime",
                    systemImage: "ipad.and.iphone"
                )

                usageReport
            }
        }
        .tint(.blue)
        .onAppear {
            if let startDate, let endDate {
                filter = DeviceActivityFilter(segment: .hourly(during: .init(start: startDate, end: endDate)))
            }
        }
    }
}

private extension ScreenUsageReportCell {

    var startDate: Date? {
        let components = Calendar.current.dateComponents([.hour, .minute], from: screenUseController.startDate)
        return Calendar.current.closestPastDateMatchingHourAndMinute(components: components, referenceDate: endDate ?? .now)
    }

    var endDate: Date? {
        let components = Calendar.current.dateComponents([.hour, .minute], from: screenUseController.endDate)
        return Calendar.current.closestPastDateMatchingHourAndMinute(components: components)
    }

    @ViewBuilder
    var usageReport: some View {
        if let filter {
            DeviceActivityReport(.bedtimeActivity, filter: filter)
                .frame(height: 140)
        }
    }
}

#Preview {
    List {
        ScreenUsageReportCell()
    }
}
